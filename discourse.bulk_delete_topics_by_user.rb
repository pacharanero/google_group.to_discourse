#helps with bulk deletion of Discourse topics - useful when you've been experimenting with a google group scrape

def bulk_delete(user=ENV['DISCOURSE_API_USER'])
  connect_discourse if @discourse_client.nil?
  topics_for_deletion = @discourse_client.topics_by(user) #gets the first 30 topics - this is Discourse's API default
  topics_for_deletion.each { |id| @discourse_client.delete_topic(id["id"]) }
  puts "#{topics_for_deletion.count} posts deleted"
end  