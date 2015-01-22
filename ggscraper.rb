require 'selenium-webdriver'
require 'discourse_api'

class Ggscraper

  def initialize
    if ENV['GOOGLE_USER'].nil? or ENV['GOOGLE_PASSWORD'].nil? or ENV['GOOGLE_GROUP_URL'].nil? 
      puts "You need to setup these environment variables: GOOGLE_USER, GOOGLE_PASSWORD and GOOGLE_GROUP_URL"
    end

    @username = ENV['GOOGLE_USER']
    @password = ENV['GOOGLE_PASSWORD']
    @ccio_url = ENV['GOOGLE_GROUP_URL']    

    @discourse_ = ENV['DISCOURSE_']

    @driver = Selenium::WebDriver.for :firefox
    @raw_driver = Selenium::WebDriver.for :firefox

    @discourse_client = nil
  end

  def go
    login
    puts "Logging in to Google Group..."

    #scroll to bottom of list of topics to get ALL the topics (need to make selenium do this)
    topics = get_topics
    puts "#{topics.count} topics found."

    topics.each do |topic|
      thread = topic.click
      #If 3 messages in thread then, the last one will be open.
      #Is there a common class element that identifies each message and thread.
      #If collapsed: span id="message_snippet_<message_id>"
      #If expanded: 'More Actions' link (under the arrow) - div id="b_action_<message_id>"
      #thread_id, message_ids = extract(thread)
      #message_ids.each do |message_id|
        #raw = get_raw_message( thread_id, message_id)
      #end

      #scraper.create_discourse_topic topic.text
    end
    #puts topic.to_s
  end

  def raw_message_test
    login(@raw_driver)
    get_raw_message("s2QXT_XDMhA","bMl2SEzl0oEJ")
    # Date: Wed, 21 Jan 2015 12:20:16 +0000
    # From: "Firstname Surname" <email@test.com>    
    # Subject: message subject
    #Message BODY
    # Extract
    #Content-Type: text/plain; charset="us-ascii"
    #Content-Transfer-Encoding: quoted-printable
    #UP TO
    # -- =
    # OR Maybe
    # To post to this group, send email to ccio@googlegroups.com.
  end

  def login(driver=@driver)
    sleep(2) 
    puts "Loading #{@ccio_url} for user #{@username}"
    driver.navigate.to @ccio_url

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
    sleep(6) #wait for it to load

    #topics = driver.find_elements(:class, 'GFP-UI5CPO')
    topics = @driver.find_elements(:tag_name, 'a')
    puts "#{topics.count} total topics found."    

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

end #end class

# Allow command line usage
if __FILE__ == $PROGRAM_NAME
  #instantiates and runs the script
  scraper = Ggscraper.new
  puts "Initializing..."

  topics = scraper.go()
end