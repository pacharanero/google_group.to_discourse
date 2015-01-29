#notes

#scraping a google group in Ruby
the content of the group is rendered in JavaScript in the browser, so initial attempts to use Mechanize met with failure: although we could log in, we only saw a series of links and none of the actual group content. Because of this we thought we should try using a browser driver like Selenium (rather than the simple web requests made by Mechanize).

The content of a Google Group seems to be obfuscated - so the element class names are meaningless:

#message snippets (click on them to expand messages)
find_elements(:class, 'GFP-UI5CCLB')

#elements with name of author
find_elements(:class, 'GFP-UI5CA1B')

#elements with content of post
find_elements(:class, 'GFP-UI5CCKB')

