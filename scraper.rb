require 'rubygems'

require 'nokogiri'
require 'mechanize'

def login
	group_signin_url = "https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fgroups.google.com%2Fd%2Fforum%2Fccio&hl=en-GB&service=groups2&passive=true"

	user = ENV['GOOGLE_USER']
	password = ENV['GOOGLE_PASSWORD']

	scraper = Mechanize.new
	scraper.user_agent = Mechanize::AGENT_ALIASES["Linux Firefox"]
	scraper.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	
	page = scraper.get group_signin_url
	google_form = page.form 
	google_form.Email = user
	google_form.Passwd = password

	group_page = scraper.submit(google_form, google_form.buttons.first)
	pp group_page

	#manual_group_page = scraper.get "https://groups.google.com/forum/#!forum/ccio"
	#pp manual_group_page

	#group_url = "https://groups.google.com/forum/#!forum/ccio"
	#doc = Nokogiri::HTML(open(group_url))
	group_page
end