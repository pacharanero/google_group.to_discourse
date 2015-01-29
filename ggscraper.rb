require 'selenium-webdriver'
require 'discourse_api'
require 'mail'
require 'nokogiri'
require 'cgi'

class Ggscraper
  attr_reader :driver, :raw_driver, :discourse_client

  def initialize
    if ENV['GOOGLE_USER'].nil? or ENV['GOOGLE_PASSWORD'].nil? or ENV['GOOGLE_GROUP_URL'].nil? or ENV['DISCOURSE_ADDRESS'].nil? or ENV['DISCOURSE_API_KEY'].nil? or ENV['DISCOURSE_API_USER'].nil? or ENV['DISCOURSE_API_USER'].nil? or ENV['DISCOURSE_CATEGORY'].nil?
      puts "You need to setup these environment variables: GOOGLE_USER, GOOGLE_PASSWORD and GOOGLE_GROUP_URL. DISCOURSE_ADDRESS, DISCOURSE_API_KEY, DISCOURSE_API_USER and DISCOURSE_CATEGORY"
    end

    @username = ENV['GOOGLE_USER']
    @password = ENV['GOOGLE_PASSWORD']
    @ccio_url = ENV['GOOGLE_GROUP_URL']        

    @driver = Selenium::WebDriver.for :firefox
    @raw_driver = Selenium::WebDriver.for :firefox

    @discourse_client = nil
  end


  def one_whole_topic( topics_store , index)
    topic = topics_store[index-1] #sets topic[:title], topic[:url], topic[:thread_id]

    #navigate to topic
    driver.navigate.to topic[:url]
    sleep (3) #wait for it to load

    #expand all the message_snippets
    minimized_messages = driver.find_elements(:xpath, "//span[contains(@id, 'message_snippet_')]")
    minimized_messages.each { |link| link.click }

    #get all messages (they are all expanded)
    expanded_messages = driver.find_elements(:xpath, "//div[contains(@id, 'b_action_')]")
    all_messages = expanded_messages #they are all expanded now so expanded_messages is same as all_messages
    puts "we have #{all_messages.count} expanded messages"

    #iterate through messages
    first_message = true 
    discourse_topic_id = nil

    all_messages.each do |message|
      message_id = message.attribute(:id).slice(-12, 12)

      puts "getting raw, for thread_id: #{topic[:thread_id]}, message_id: #{message_id}"      
      raw_email = get_raw_message( topic[:thread_id], message_id )     
      email = Mail.new raw_email
      puts "We have email: date: #{email.date}, from #{email.from}, subject: #{email.subject}"

      if first_message
        first_message = false
        puts "First message so need to create thread. About to create discourse topic #{topic[:title]}"

        topic_parameters = create_discourse_topic( topic, email )
        if topic_parameters
          puts "Created topic: #{topic_parameters["topic_id"]}"
          discourse_topic_id = topic_parameters["topic_id"]
        else
          puts "ERROR: Topic was NOT created on discourse - #{topic[:url]}"
        end

      else
        puts "This should be posted to existing thread"
        post_parameters = create_discourse_topic_post(discourse_topic_id, email)
        puts "Post created on discourse - post id: #{post_parameters["id"]}"
      end

    end

  end  


  def build_topics_store
    login    
    login @raw_driver
    topics = get_topics
    puts "#{topics.count} topics found."

    topics_store = []
    # visit all of the topics before leaving the page
    topics.each do |topic|      
      thread_id = get_thread_id_from_url topic.attribute(:href)
      topic = { title: topic.text, url: topic.attribute(:href), thread_id: thread_id }
      topics_store << topic 
    end
    puts "#{topics_store.count} topic attributes stored"

    topics_store
  end

  def go
    puts "Logging in to Google Group..."

    login    
    login @raw_driver
    
    topics = get_topics
    puts "#{topics.count} topics found."
    
    topics_store = []
    # visit all of the topics before leaving the page
    topics.each do |topic|      
      thread_id = get_thread_id_from_url topic.attribute(:href)
      topic = { title: topic.text, url: topic.attribute(:href), thread_id: thread_id }
      topics_store << topic 
    end
    puts "#{topics_store.count} topic attributes stored"

    # Visit and migrate each of the threads in turn.
    topics_store.each do |topic|      
      puts "thread id: #{topic[:thread_id]} for topic: #{topic[:title]}"
      puts "url: #{topic[:url]}"

      driver.navigate.to topic[:url]
      sleep(1)
      #open_each_message_snippet topic[:url] #Issues with dom not being in view, solved with minimized messages below      

      #If 3 messages in thread then, the last one will be open.
        #If collapsed: span id="message_snippet_<message_id>"  
        #If expanded: 'More Actions' link (under the arrow) - div id="b_action_<message_id>"
      #minimized_messages = nil #need to find these and open by clicking on them      
      minimized_messages = driver.find_elements(:xpath, "//span[contains(@id, 'message_snippet_')]")
      expanded_messages = driver.find_elements(:xpath, "//div[contains(@id, 'b_action_')]")
      
      all_messages = expanded_messages.concat minimized_messages
      
      if minimized_messages.count + expanded_messages.count == all_messages
      end 

      if all_messages.count == 0
        puts "****ERROR: NO MESSAGES at url: #{topic[:url]}"
      else
        puts "we have #{all_messages.count} expanded messages"
        first_message = true 
        discourse_topic_id = nil

        all_messages.each do |message|
          message_id = expanded_messages.first.attribute(:id).split("_").last

          puts "getting raw, for thread_id: #{topic[:thread_id]}, message_id: #{message_id}"      
          raw_email = get_raw_message( topic[:thread_id], message_id )     
          email = Mail.new raw_email
          puts "We have email: date: #{email.date}, from #{email.from}, subject: #{email.subject}"

          if first_message
            first_message = false
            puts "First message so need to create thread. About to create discourse topic #{topic[:title]}"

            topic_parameters = create_discourse_topic( topic, email )
            if topic_parameters
              puts "Created topic: #{topic_parameters["topic_id"]}"
              discourse_topic_id = topic_parameters["topic_id"]
            else
              puts "ERROR: Topic was NOT creasted on discourse - #{topic[:url]}"
            end

          else
            puts "This should be posted to existing thread"
            post_parameters = create_discourse_topic_post(discourse_topic_id, email)
            puts "Post created on discourse - post id: #{post_parameters["id"]}"
          end

        end
        
      end  

    end #end topics iteration
    
    close_browsers

    topics_store.to_json
  end  

  def login(driver=@driver)
    puts "Loading #{@ccio_url} for user #{@username}"
    driver.navigate.to @ccio_url
    sleep(2) 
    #find the right elements
    username_field = driver.find_element(:id, 'Email')
    password_field = driver.find_element(:id, 'Passwd')
    signin_button = driver.find_element(:id, 'signIn')

    #fill in credentials
    username_field.send_keys(@username)
    password_field.send_keys(@password)
    signin_button.click
  end

  def get_topics
    populated_topics = []

    # It seems that google groups initial load is 30 threads.       
    puts "Scroll down to the bottom of the Group in the Selenium window (yes, manually!)"
    #user scrolls down MANUALLY then get topics
    sleep(20)
    puts "5 seconds left to finish scrolling"
    sleep(5)

    #@driver.find_elements(:tag_name, 'a').last.location_once_scrolled_into_view #scroll to last topic. Preferable, but doesn't work.            
    
    topics = @driver.find_elements(:tag_name, 'a')
    puts "#{topics.count} total topics found."    

    # We only want the links that include "#!topic/"
    topics.each do |topic|
      if !topic.nil? and !topic.attribute(:href).nil? and topic.attribute(:href).include? "#!topic/" # it is a topic.
        puts "#{topic.text}"                
        populated_topics << topic                    
      end
    end

    populated_topics
  end

  def open_each_message_snippet(topic_url)
    # Only useable if all of the messages are within 
    @driver.navigate.to topic_url
    snippets = @driver.find_elements(:class, 'GFP-UI5CCLB') #finds the message-snippets

    snippets.each do |snippet|
      snippet.location_once_scrolled_into_view
      snippet.click
    end
  end

  def get_raw_message( thread_id, message_id )
    raw_url = "https://groups.google.com/forum/message/raw?msg=ccio/#{thread_id}/#{message_id}"
    
    @raw_driver.navigate.to raw_url
    #TODO: Check for 400 error here. Seems about 1 in 20 or so is generating a bad request.
    puts "raw: #{@raw_driver.page_source}"

    return Nokogiri::HTML(CGI.unescapeHTML(@raw_driver.page_source)).content
  end

  def get_thread_id_from_url( thread_url )
    #Format: "https://groups.google.com/forum/#!topic/ccio/g9qK6Zefb3w" 

    thread_url.split("#!topic")[1].split("/").last
  end

  def connect_discourse
    @discourse_client = DiscourseApi::Client.new( ENV['DISCOURSE_ADDRESS'] )
    @discourse_client.api_key = ENV['DISCOURSE_API_KEY']
    @discourse_client.api_username = ENV['DISCOURSE_API_USER'] 
  end


  def create_discourse_topic( topic, email=nil )
    connect_discourse if @discourse_client.nil? 
    topic_parameters = nil
        topic_parameters = @discourse_client.create_topic(
        category: "#{ENV['DISCOURSE_CATEGORY']}",
        skip_validations: true,
        auto_track: false,
        title: "#{topic[:title]}",
        raw: "Imported message. Original thread at: #{topic[:url]}
          Sender:#{email.from}. Date:#{email.date}.
          Message: #{email.text_part}"
      )
    return topic_parameters
  end

  def create_discourse_topic_post( topic_id, email )
    connect_discourse if @discourse_client.nil? 
    
    post_parameters = nil
    puts "topic_id: #{topic_id.to_s}, Sender:#{email.from}. Date:#{email.date}. Message: #{email.text_part}"
          
      post_parameters = @discourse_client.create_post(
        topic_id: "#{topic_id}",                
        raw: "Imported reply. Sender:#{email.from}. Date:#{email.date}. Message: #{email.text_part}"
      )
     
      puts "***create_discourse_topic_post EXCEPTION: #{topic_id}"
    

    post_parameters
  end

  def bulk_delete(user=ENV['DISCOURSE_API_USER'])
    connect_discourse if @discourse_client.nil?
    topics_for_deletion = @discourse_client.topics_by(user) #gets the first 30 topics - this is Discourse's API default
    topics_for_deletion.each { |id| @discourse_client.delete_topic(id["id"]) }
    puts "#{topics_for_deletion.count} posts deleted"
  end  

  def close_browsers
    @driver.close
    @raw_driver.close
  end  

end #end class

# Allow command line usage
if __FILE__ == $PROGRAM_NAME
  #instantiates and runs the script
  scraper = Ggscraper.new
  puts "Initializing..."

  topics = scraper.go()
end