# gg.to_d

##IMPORTANT
* This repo currently only works with Discourse v1.7.2. To work with latest Discourse, it needs refactoring to take account of some improvements in Discourse's import script library. I **will** update it as soon as I can find time, however I'm not anticipating this to be in the immediate future due to other commitments.
* I'm really sorry, but I cannot provide support for this script. By all means use it, fork it, tweak it, add some tests :-) etc.
* If you wish to engage my services in migrating your Google Group to Discourse then I may be able to help, please contact me via [Discourse Meta](https://meta.discourse.org/c/marketplace) (I'm 'pacharanero' on there). Paying for my time will accelerate improvements to this open source script, for the benefit of all. My current 'production' version will always be free and open source and in a **public** repo, (most likely this one).

-------

Here is a 'working prototype' of a google group migration script that attempts to be more 'all-in-one' and reduce the number of steps, complexity and difficulty of doing google group imports.

Having finally gotten around to doing a pro-bono google group import I promised to do for the wonderful [Valentina Project](http://valentina-project.org/), I had to re-familiarise myself with the available google group scraping tools, as suggested to me by @erlend_sh from the Discourse Team, who pointed me in the direction of a few google group scraping libraries and Discourse's own mbox importer script. So while it's all in my head I thought I'd have a go at a more user-friendly import script, and some documentation for it.

Thanks to @steinwaywhw at Discourse Meta for his work, both in https://meta.discourse.org/t/how-to-import-google-groups-to-discourse/47074/2 and in https://meta.discourse.org/t/an-importer-for-google-groups/45624, without which I wouldn't have been able to do this.

# Notes
* I think I may have solved the [problem](https://meta.discourse.org/t/an-importer-for-google-groups/45624/7) of email addresses being redacted by Google Groups, (it doesn't happen if you are logged into Google Groups with a 'Manager' level account) so that now, the `mbox.rb` importer can create users in Discourse with the correct email addresses. The rightful owners of those created users would then only need to do a password reset in order to be able to log into their new user on Discourse, and all their Google Group posts would be correctly assigned to them. I've tested this on a real migration, it works, and I'm keen to get feedback from other testers.
* I've tried to use the OO design pattern established in the other import scripts, for example `ImportScripts::Mbox` subclasses `ImportScripts::Base`. In my case, I wanted to use a lot of functionality from `ImportScripts::Mbox`, so my script is a subclass of `ImportScripts::Mbox`.
* It works.... but it's definitely not finished yet and I'd appreciate constructive criticism, pull requests and amusing emoji.

# How to use it

You will need to be a little bit familiar with the Linux command line, SSH and stuff like that. I've tried to make the step-by-step instructions as clear as possible, but there might be slight variations in the output of certain commands. Please reply to the [Discourse Meta thread](https://meta.discourse.org/t/migration-of-google-groups-to-discourse/48012) or create a GitHub Issue if you are having problems.

1. **Cookies**. In order to be able to extract users' email addresses correctly from the Google Group, you will need to have **Manager** access to the Google Group. Having logged into Google Groups (on your normal computer) with this Manager account, export the Google  cookies from your browser. (I used the [cookies.txt](https://chrome.google.com/webstore/detail/cookiestxt/njabckikapfpffapmjgojcnbfjonfjfg) Chrome extension to get the cookies.txt file (Without this step, the scrape **will** still work BUT the email addresses are truncated/redacted by Google Groups so they look like this: `marcu....@gmail.com`, and of course this messes up creation of new users on Discourse)

1. **Upload cookies.txt.** Once you have the cookies.txt file, the easiest way to get it into your Docker container from your computer is to **upload it as an attachment to any post in your discourse forum**. You need to enable upload of .txt file types, in the site settings (There alternative way requires messing about with both `scp` and then `docker cp`, but is of course fine as well) You will need the file path for the next step, you can get  the URL from the post, it will be something like: `/uploads/default/original/1X/245aa0cdc6847cf59647e1c7102e253e99d40b69.txt`

1. **SSH into your server**

`user@my-laptop ~ $ ssh user@your-discourse-server`

1. **Change directory into the Discourse directory**

`user@your-discourse-server ~ $ cd /var/discourse`

1. **Enter the Discourse Docker container**

using the ./launcher tool.
`user@your-discourse-server /var/discourse $ ./launcher enter app`

1. **Copy cookies.txt to `/tmp/`**

so that the import script can find it. Prepend `/var/www/discourse/public` to the URL from the previous step, this gives you the full file path to use with the `cp` (unix copy) command:

`root@your-container ~ # cp '/var/www/discourse/public/uploads/default/original/1X/245aa......40b69.txt /tmp/`

1. **Install some stuff**

This is stuff that's needed by `mbox.rb`, the importer script, for its index
`root@your-container ~ # apt install sqlite3 libsqlite3-dev`
`root@your-container ~ # gem install sqlite3`

1. **Change into the import scripts directory**

with the `cd` command.
`root@your-container ~ # cd /var/www/discourse/script/import_scripts`

1. **Get the google group script**

`root@your-container /var/www/discourse/script/import_scripts # git clone https://github.com/pacharanero/google_group.to_discourse.git`

1. **Move the downloaded script (and the altered version of mbox.rb it depends upon) into the current directory**

`mv google_group.to_discourse/* .`

1. **Change user**

Change user to the `discourse` user so that you can make changes to the database
`# su discourse`

1. **Run the script!**

`# ruby googlegroups.rb` _`name-of-your-google-group`_


##License
* GPLv3 License, same as Discourse itself.
* I'm happy to contribute the code to the main Discourse repo, however because I had to change mbox.rb in order to make it work, and other import scripts depend on mbox.rb, I haven't submitted a PR yet.

##Contributing
* Fork the repo to your own GitHub account.
* Make changes & commit them.
* Submit a PR explaining the reason for the changes and why I should include them.


Marcus
