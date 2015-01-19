require 'selenium-webdriver'

#setup
user = 'pacharanero'
pass = 'cxn^ka7$OI3w65df3jmTWnaU$N1a3V'
ccio_url = 'https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fgroups.google.com%2Fd%2Fforum%2Fccio&hl=en-GB&service=groups2&passive=true'

#instantiate and navigate
driver = Selenium::WebDriver.for :firefox
driver.navigate.to ccio_url

#login page
username = driver.find_element(:id, 'Email')
password = driver.find_element(:id, 'Passwd')
sign = driver.find_element(:id, 'signIn')

#fill in credentials
username.send_keys(user)
password.send_keys(pass)
sign.click

