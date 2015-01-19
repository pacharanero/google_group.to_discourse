def go
	root_group_page = "https://groups.google.com/forum/#!forum/ccio"

	login_to_google
	login_to_discourse
	
	link_to_next_page = root_group_page

	while link_to_next_page

		topic_links, link_to_next_page = get_index_page root_group_page

		topic_links.each do |topic_link|
			puts "Retrieving: #{topic_link}"
			topic_details = get_topic_details topic_link

			puts "Migrating #{topic_details[:topic_title]}"
			migrate_topic_to_discourse topic_details
		end

	end
end

def login_to_google
	group_signin_url = "https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fgroups.google.com%2Fd%2Fforum%2Fccio&hl=en-GB&service=groups2&passive=true"

	user = ENV['GOOGLE_USER']
	password = ENV['GOOGLE_PASSWORD']
end

def login_to_discourse

end

def get_index_page( page_url)
	topic_links = []
	link_to_next_page = nil

	[ topic_links, link_to_next_page ]
end

def get_topic_details( topic_url )
	topic_title = "test title"
	topic_author_name = "test author"
	topic_author_email = "test@test.com"
	topic_datetime = "20/1/2014"
	topic_body = "A test body.A test body.A test body.A test body.A test body.A test body."

	#page = open(topic_url)
	#pp page

	#TODO-replies

	{ title: topic_title, author_name: topic_author_name, author_email: topic_author_email, publised_at: topic_datetime, body: topic_body }
end

def migrate_topic_to_discourse( topic_details )
	#initially lets use our main user, and prepend the author to the subject.
	# and indicate in the body that this is a migrated post, buy author, from date

	body = "Migrated from Google Group. Original by #{topic_details[:topic_author_name]},#{topic_details[:topic_author_email]}. #{topic_details[:body]}"
	title = "#{topic_details[:title]}"

	#create new topic
end