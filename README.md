##Google Groups to Discourse migration

Migrating away from a private Google Group is not easy. It would seem to be made deliberately so by Google.

1. there is no API
2. there is no API
3. the entire content is rendered in-browser from JS so HTML requesting tools such as the Ruby Mechanize gem don't work (you can log in but you can't see any content)
4. the HTML tags are (it seems deliberately) obfuscated - they are meaningless in English so it's hard to work out what CSS selectors to go for when scraping the page
5. I'm told there are Captchas if you go over a certain rate limit for page requests (although I didn't encounter this problem)

Discourse was the easy bit, because it has a comprehensive read/write API: https://github.com/discourse/discourse_api

##Scraper/Import Tool gg.to_d.rb
gg.to_d.rb uses Ruby Selenium to automate a Firefox browser which navigates to the Google Group, logs in, and scrapes all the topics from the front page. It then iterates through these to collect all the data from each Topic into a hash, which it then uses to create a topic on Discourse and append all subsequent posts to that topic.

## Dependencies
* Firefox
* Selenium

##How To Use
1. I suggest using a dev/testing instance of Discourse rather tan your production/live instance, at least while you're getting things figured out.
1. Set up a user for the Google Group you want to scrape and obtain login credentials for that user.
1. Set up a user for the Discourse group who has sufficient privileges to post without restriction (in practice just make them an Admin). All scraped posts will be posted by this user, although a header will be inserted so that the original author of the post on the Google Group is clear.
1. Create an API key for the Discourse User (done in <http://yourdiscoursedomain>/admin/users/<username> ).
1. Create a suitable Category in Discourse for the scraped content to go into.
1. Temporarily remove rate limiting for posts on Discourse (done in <http://yourdiscoursedomain>/admin/site_settings/category/rate_limits ).
1. edit env.sh.template to contain the correct credentials for the above users, the URL of the Google Group and the Discourse instance:

```bash
export GOOGLE_USER=""               # Google Group username 
export GOOGLE_PASSWORD=""           # Google Group user's password
export GOOGLE_GROUP_URL=""          # URL to Google **with redirect to the Google Group appended**
                                    # get this by trying to navigate to the Google Group
                                    # when you are logged out - you will be taken to the login page, but the 
                                    # URL in the address bar will contain the redirect URL as well. C&P this.
export DISCOURSE_ADDRESS=""         # URL of the Discourse server
export DISCOURSE_API_KEY=""         # API key for the Discourse scraper user
export DISCOURSE_API_USER=""        # Username or the Discourse scraper user
export DISCOURSE_CATEGORY=""        # Category that scraped content will go into

```
1. Rename the file env.sh (or whatever_you_like.sh)
1. Open a terminal (oh yeah, if you're on Windows, er... sorry?)
1. run `$ source env.sh`
1. run irb
```
irb 001 > load 'gg.to_d.rb
irb 002 > my_scraper = GoogleGroupToDiscourse.new
```
1. A Selenium browser window (Firefox) will appear, and it should navigate to the login page of your Google Group, enter your credentials, and login.
1. In irb, type 'my_scraper.scrape_the_lot'
1. The program will ask you to scroll down the page in the Selenium browser until you reach the bottom. This is to ensure that all topics are scraped. It's very hacky but so far the only reliable way (see Known Issues)
1. You will get a list of every topic in your Google Group scrolling in the terminal
1. It will then start iterating through these and uploading to Discourse with progress reports
1. Log into Discourse and watch it happening, while the Selenium window does it's eerie thing, and the command line scrolls pleasingly.
1. If you have problems at any stage look in the 'Known Issues' section to see if it is a new problem or one we know about, and maybe find a solution
1. Reinstate normal rate limits on Discourse
1. consider Flattring (by Favouriting the repo)
1. Or: donate to our community hackspace project, @Leigh_Hackspace www.leighhack.org using this PayPal link: [https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ERQZWWL7HARHY]

##Notes/Alternative Usage
* If you look at the source, there are a couple of other methods that might be of help, some of which are even working ;-)
* You can break down the process of the scrape into the separate sections:
  * `topics = my_scraper.get_topics`                            # gets all topics, their URLs, and topic_id
  * `messages = my_scraper.get_messages (topics[ <index> ])`    # gets the messages for a particular topic
  * `my_scraper.send_to_discourse ( messages )`                 # sends the message just scraped to Discourse
* In particular there is a `bulk_delete(username=defaultuser)` method, for when you have been playing with scraping and it's all gone wrong

##Known Issues/Imperfections
1. And most glaring during scraping - I still haven't worked out a way to scroll to the bottom of the Google Group page in Selenium - various approaches were tried but since the links below the bottom of the page don't actually *exist* (aren't yet rendered) until you scroll down, you can't reference them in Selenium in order to make it scroll down. And there don't seem to be any direct controls for scrolling.
1. Users and posting dates of the google group are not replicated in Discourse posting. All posts are made by a single Discourse user, although a header is inserted containing the name of the user that posted and the date of the original posting, as well as a link to the original thread on Google Groups
1. `Selenium::WebDriver::Error::StaleElementReferenceError: Element is no longer attached to the DOM` - sometimes, for reasons not clear to me, the DOM either changes or something happens to Selenium's binding of DOM to Ruby Object, and it can't find stuff. Retrying, starting from that Topic seems to work, presumably the DOM is in some way refreshed. On my roadmap is to trap this error and auto-retry with a backoff and limit.
1. Email Cruft. \#GIGO. If there are loads of email signatures and other crap in the emails as they are on Google Groups, then this cruft will also be imported into Discourse.

##New issues and contributions
Please log issues in GitHub. Pull requests are welcome.
Contact me on [marcusbaw@gmail.com]

##Roadmap
* command line usage
* scrape a Range of topics (eg from topic 11..45)
* trap 'Selenium - Element is no longer attached to the DOM' error and auto-retry with backoff and limit
* cruft auto-remove (regex scanning and deletion)
* scrape list of Google Group users, create these users on Discourse, and map posts across to the correct user on upload (non-trivial but I am open to paying customers who want this)
