google-groups-scraper
=====================

###ggscraper.rb howto (so far)
    git clone git@github.com:pacharanero/google-groups-scraper.git
    cd google-groups-scraper
    irb
      > require_relative 'ggscraper'
      > scraper = Ggscraper.new(<username>, <password>, <google groups login with referrer url>) #creates window & navs to login)
      > scraper.login #logs in 
