require 'selenium-webdriver'

class Ggscraper

  def initialize
    @username = ENV['GOOGLE_USER']
    @password = ENV['GOOGLE_PASS']
    @ccio_url = ENV['GOOGLE_URL']
    @driver = Selenium::WebDriver.for :firefox
    @driver.navigate.to @ccio_url
  end

  def login
    #find the right elements
    username_field = @driver.find_element(:id, 'Email')
    password_field = @driver.find_element(:id, 'Passwd')
    signin_button = @driver.find_element(:id, 'signIn')

    #fill in credentials
    username_field.send_keys(@username)
    password_field.send_keys(@password)
    signin_button.click
  end

  def get_topics
    @driver.find_elements(:tag_name, 'a').last.location_once_scrolled_into_view #scroll to last topic
    sleep (8) #wait for it to load
    return topics = @driver.find_elements(:tag_name, 'a')
  end

end

#instantiates and runs the script
scraper = Ggscraper.new
puts "Initializing..."
scraper.login
puts "Logging in to Google Group..."
#scroll to bottom of list of topics to get ALL the topics (need to make selenium do this)
topics = scraper.get_topics
puts "#{topics.count} topics found."




