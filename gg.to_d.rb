require 'selenium-webdriver'
require 'mail'
require 'nokogiri'
require 'cgi'
require 'json'
require 'discourse_api'


class GoogleGroupsScrapetoJSON
  attr_reader :driver, :raw_driver

  @discourse_client = nil



  # set up variables from the env file
  def initialize
    
  	if ENV['GOOGLE_USER'].nil? or ENV['GOOGLE_PASSWORD'].nil? or ENV['GOOGLE_GROUP_URL'].nil? or ENV['DISCOURSE_ADDRESS'].nil? or ENV['DISCOURSE_API_KEY'].nil? or ENV['DISCOURSE_API_USER'].nil? or ENV['DISCOURSE_API_USER'].nil? or ENV['DISCOURSE_CATEGORY'].nil?
  	  puts "You need to setup these environment variables: GOOGLE_USER, GOOGLE_PASSWORD and GOOGLE_GROUP_URL. DISCOURSE_ADDRESS, DISCOURSE_API_KEY, DISCOURSE_API_USER and DISCOURSE_CATEGORY"
  	end

    # set local variables to environment variables
  	@username = ENV['GOOGLE_USER']
  	@password = ENV['GOOGLE_PASSWORD']
  	@google_group_url = ENV['GOOGLE_GROUP_URL']        

    # initialize a driver to look up DOM information and another for scraping raw email information
  	@driver = Selenium::WebDriver.for :firefox
    login @driver   
  end

  # log in to google group
  def login(driver)
    puts "I'm loading #{@google_group_url}. Wait and be patient\n\n"
    driver.navigate.to @google_group_url
    sleep(3)

    # find the right elements
    username_field = driver.find_element(:id, 'Email')
    password_field = driver.find_element(:id, 'Passwd')
    signin_button = driver.find_element(:id, 'signIn')

    puts "Now I'm logging in with the username #{@username} and the password #{@password}. As if you care.\n\n"
    # fill in credentials
    username_field.send_keys(@username)
    password_field.send_keys(@password)
    signin_button.click
  end

  def get_topics
    @populated_topics = []
    # scroll to the bottom of google group (to force Groups to load - and therefore render - all the threads)
    puts "Scroll down MANUALLY to the bottom of the Selenium window. Press Enter when ready"
    x = gets
    # user scrolls down MANUALLY then get topics
    
    # get all the links (which includes all the topics but also other stuff)
    topics = @driver.find_elements(:tag_name, 'a')

    # We only want the links that include "#!topic/"
    topics.each do |topic|
      if !topic.nil? and !topic.attribute(:href).nil? and topic.attribute(:href).include? "#!topic/" # it is a topic.
        puts "#{topic.text}"
        thread_id = topic.attribute(:href).split("/").last #Format: "https://groups.google.com/forum/#!topic/ccio/g9qK6Zefb3w" 
        topic = { title: topic.text, url: topic.attribute(:href), thread_id: thread_id }           
        @populated_topics << topic                    
      end
    end

    puts "#{@populated_topics.count} topics in this Google Group\n\n"  
    return @populated_topics
  end

  def get_messages (topic)
    topic[:messages] =[] # messages will be appended to this as an array of hashes
    @driver.navigate.to topic[:url]
    sleep (3) #wait for it to load
    # expand all the message_snippets
    minimized_messages = @driver.find_elements(:xpath, "//span[contains(@id, 'message_snippet_')]")
    minimized_messages.each { |link| link.click; sleep (0.1)}
    # get all messages
    all_messages = @driver.find_elements(:xpath, "//div[contains(@id, 'b_action_')]")
    puts "#{all_messages.count} messages in this thread"
    # iterate through messages
    sender = @driver.find_elements(:class, 'GFP-UI5CA1B')
    date = @driver.find_elements(:class, 'GFP-UI5CDKB')
    body = @driver.find_elements(:class, 'GFP-UI5CCKB').reject! { |c| c.text=="" } #reject blank ones
    all_messages.each_with_index do |message, index|
      topic[:messages] << { sender: sender[index].text, date: date[index].attribute(:title), body: body[index].text }
    end
    return topic
  end

  def scrape_the_lot
    topics = get_topics
    topics.each do |topic|
      messages = get_messages( topic )
      # this would be where to insert any cruft-removal code
      send_to_discourse( messages )
      puts "All topics migrated to Discourse"
      close_browsers
    end

  def save_all_topics_json(start_at_topic_number=0)
    topics = get_topics
    Dir.mkdir("topics") unless Dir.exist?("topics")
    Dir.chdir("topics")
    topics.each_with_index do |topic, topic_number|
      next if topic_number+1 < start_at_topic_number
      topic_json = get_messages(topic).to_json
      File.open("topic#{topic_number+1}.json", "w") do |f|
        f.write(topic_json)
      end
    end
    puts "All topics saved to ./topics/ directory in JSON format"
  end

  def save_topic_json(topic)
    topic_json = get_messages(topic).to_json
    File.open("topic#{topic[:thread_id]}.json", "w") do |f|
      f.write(topic_json)
    end
    return topic_json
  end

  def build_topics_store
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

  def connect_discourse
    @discourse_client = DiscourseApi::Client.new( ENV['DISCOURSE_ADDRESS'] )
    @discourse_client.api_key = ENV['DISCOURSE_API_KEY']
    @discourse_client.api_username = ENV['DISCOURSE_API_USER'] 
    @destination_category = ENV['DISCOURSE_CATEGORY']
  end

  def send_to_discourse(topic_object) #pass in @topic object as described above
    connect_discourse if @discourse_client.nil?
    first_message = true
    topic_object[:messages].each do |message| 
      if first_message
        first_message = false
        puts "Creating Discourse topic: #{topic_object[:title]}"
        topic_parameters = create_discourse_topic( topic_object, message )
        if topic_parameters
          puts "Created Discourse topic ID: #{topic_parameters["topic_id"]}"
          topic_object[:discourse_topic_id] = topic_parameters["topic_id"]
        else
          puts "ERROR: Topic was NOT created on discourse - #{topic_object[:url]}"
        end
      else
        post_parameters = create_discourse_post( topic_object, message )
        puts "Created Discourse post ID: #{post_parameters["id"]}"
      end
    end  
  end

  def create_discourse_topic( topic_object, message )
    connect_discourse if @discourse_client.nil? 
    topic_parameters = nil
    topic_parameters = @discourse_client.create_topic(
      category: "#{@destination_category}",
      skip_validations: true,
      auto_track: false,
      title: "#{topic_object[:title]}",
      raw: "**Imported Google Group message. Original thread at: #{topic_object[:url]} Import Date: #{Time.now}.**\n `Sender:#{message[:sender]}`.\n `Date:#{message[:date]}.`\n\n#{message[:body]}"
      )
    return topic_parameters
  end

  def create_discourse_post( topic_object, message )
    post_parameters = nil
    post_parameters = @discourse_client.create_post(
      topic_id: "#{topic_object[:discourse_topic_id]}",                
      raw: "**Imported Google Group message.**\n `Sender:#{message[:sender]}`.\n `Date:#{message[:date]}.`\n\n#{message[:body]}"
      )
    return post_parameters
  end


  def close_browsers
    @driver.close
    @raw_driver.close
  end

  #helps with bulk deletion of Discourse topics - useful when you've been experimenting with a google group scrape

  def bulk_delete(user=ENV['DISCOURSE_API_USER'])
    connect_discourse if @discourse_client.nil?
    topics_for_deletion = @discourse_client.topics_by(user) #gets the first 30 topics - this is Discourse's API default
    topics_for_deletion.each { |id| @discourse_client.delete_topic(id["id"]) }
    puts "#{topics_for_deletion.count} posts deleted"
  end  

end #class

