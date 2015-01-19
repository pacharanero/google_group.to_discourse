require 'selenium-webdriver'

class Ggscraper

	def initialize (username, password, url)
		@username = username
		@password = password
		@ccio_url = url
		@driver = Selenium::WebDriver.for :firefox
		@driver.navigate.to @ccio_url
		return @driver
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

end




