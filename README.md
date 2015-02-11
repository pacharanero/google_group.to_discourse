#Scraping Google Group Content

###Google Groups scraping - general points
* Migrating away from a Google Group is not easy. It would seem to be deliberately so
* There is no API that allows reading the topics or posts programmatically, although there is a partial API which allows user and permissions management only: https://developers.google.com/admin-sdk/groups-settings/v1/reference/groups
* Scraping the content seemed like the only way to extract the content. Initial attempts with the Ruby Mechanize gem failed, because the Groups page content is rendered in-browser, so simple HTTP requests for content return blank.
* This is similar to the experience of this blogger, who also described a failure with HTTP requests (in Python) and therefore switched to using Selenium to automate a web browser: https://sputnikus.github.io/google_groups_scrape and https://sputnikus.github.io/google_groups_scrape_again

###Migration to Discourse
Discourse was the easy bit, because it has a comprehensive read/write API: https://github.com/discourse/discourse_api

