require 'selenium-webdriver'
require 'discourse_api'

class Ggscraper
  attr_reader :driver

  def initialize
    if ENV['GOOGLE_USER'].nil? or ENV['GOOGLE_PASSWORD'].nil? or ENV['GOOGLE_GROUP_URL'].nil? or ENV['DISCOURSE_ADDRESS'].nil? or ENV['DISCOURSE_API_KEY'].nil? or ENV['DISCOURSE_API_USER'].nil?
      puts "You need to setup these environment variables: GOOGLE_USER, GOOGLE_PASSWORD and GOOGLE_GROUP_URL. DISCOURSE_ADDRESS, DISCOURSE_API_KEY, and DISCOURSE_API_USER"
    end

    @username = ENV['GOOGLE_USER']
    @password = ENV['GOOGLE_PASSWORD']
    @ccio_url = ENV['GOOGLE_GROUP_URL']        

    @driver = Selenium::WebDriver.for :firefox
    @raw_driver = Selenium::WebDriver.for :firefox

    @discourse_client = nil
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

      #If 3 messages in thread then, the last one will be open.
        #If collapsed: span id="message_snippet_<message_id>"  
        #If expanded: 'More Actions' link (under the arrow) - div id="b_action_<message_id>"
      #minimized_messages = nil #need to find these and open by clicking on them      
      expanded_messages = driver.find_elements(:xpath, "//div[contains(@id, 'b_action_')]")
      
      if expanded_messages.count == 0
        puts "****ERROR: NO EXPANDED MESSAGES at url: #{topic[:url]}"
      else
        puts "we have #{expanded_messages.count} expanded messages"
        #expanded_messages.each do |message|
          #raw = get_raw_message( thread_id, message_id)
        #end
        message_id = expanded_messages.first.attribute(:id).split("_").last

        puts "getting raw, for thread_id: #{topic[:thread_id]}, message_id: #{message_id}"      
        raw_email = get_raw_message( topic[:thread_id], message_id )      
      end  

      puts "about to create discourse topic #{topic[:title]}"
      create_discourse_topic topic[:title]
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

    @driver.find_elements(:tag_name, 'a').last.location_once_scrolled_into_view #scroll to last topic
    #TODO-the scroll to last needs repeating until there is no more messages.
    # Would be useful to detect the <current_number> of <total_topics> or even human enter the number as part of the initiation.
    # It seems that google groups initial load is 30 threads. 
    
    sleep(4) #wait for it to load
    
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

  def get_raw_message( thread_id, message_id )
    raw_url = "https://groups.google.com/forum/message/raw?msg=ccio/#{thread_id}/#{message_id}"
    
    @raw_driver.navigate.to raw_url
    #TODO: Check for 400 error here. Seems about 1 in 20 or so is generating a bad request.
    puts "raw: #{@raw_driver.page_source}"

    @raw_driver.page_source
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

  def create_discourse_topic( topic )
    connect_discourse if @discourse_client.nil? 

    @discourse_client.create_topic(
      category: "Help",
      skip_validations: true,
      auto_track: false,
      title: "#{topic}",
      raw: "This is the raw markdown for my post"
    )
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