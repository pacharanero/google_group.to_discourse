#takes serialised google group content from JSON store and uploads topics to Discourse
require 'discourse_api'

@discourse_client = nil


def connect_discourse
  @discourse_client = DiscourseApi::Client.new( ENV['DISCOURSE_ADDRESS'] )
  @discourse_client.api_key = ENV['DISCOURSE_API_KEY']
  @discourse_client.api_username = ENV['DISCOURSE_API_USER'] 
end

def create_discourse_topic( topic, email=nil )
  connect_discourse if @discourse_client.nil? 
  topic_parameters = nil
  topic_parameters = @discourse_client.create_topic(
    category: "#{ENV['DISCOURSE_CATEGORY']}",
    skip_validations: true,
    auto_track: false,
    title: "#{topic[:title]}",
    raw: "Imported message. Original thread at: #{topic[:url]}
      Sender:#{email.from}. Date:#{email.date}.
      Message: #{email.text_part}"
    )
  
  return topic_parameters
end


def create_discourse_topic_post( topic_id, email )
  connect_discourse if @discourse_client.nil? 
  
  post_parameters = nil
  puts "topic_id: #{topic_id.to_s}, Sender:#{email.from}. Date:#{email.date}. Message: #{email.text_part}"
        
  post_parameters = @discourse_client.create_post(
    topic_id: "#{topic_id}",                
    raw: "Imported reply. Sender:#{email.from}. Date:#{email.date}. Message: #{email.text_part}"
    )
     
  return post_parameters
end