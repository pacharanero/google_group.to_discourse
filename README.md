#google-groups-scraper

###Google Groups scraping - general points
Migrating away from a Google Group is not easy. It would seem to be deliberately so!

There is no API that allows reading the topics or posts programmatically, although there is a partial API:
https://developers.google.com/admin-sdk/groups-settings/v1/reference/groups

Scraping the content seemed like the only way to extract the content. Initial attempts with the Ruby Mechanize gem failed, because the Groups page content is rendered in-browser, so simple HTTP requests for content return blank.

This is similar to the experience of this blogger, who also described a failure with HTTP requests (in Python) https://sputnikus.github.io/google_groups_scrape and https://sputnikus.github.io/google_groups_scrape_again

###Migration to Discourse
Discourse was the easy bit, providing as it does a comprehensive read/write API: https://github.com/discourse/discourse_api

##Usage

* use a **test** instance of Discourse to start with!

* tbc


###ggscraper.rb howto (so far)
    git clone git@github.com:pacharanero/google-groups-scraper.git
    cd google-groups-scraper
    irb
      > require_relative 'ggscraper'
      > scraper = Ggscraper.new(<username>, <password>, <google groups login with referrer url>) #creates window & navs to login)
      > scraper.login #logs in 
