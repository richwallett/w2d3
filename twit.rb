require 'addressable/uri'
require 'rest-client'
require 'nokogiri'
require 'open-uri' # what's this for?
require 'json'
require 'oauth'
require './secrets.rb'
require 'launchy'
require 'yaml'

CONSUMER = OAuth::Consumer.new(
CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")


class User
  def initialize(username)
    @username = username
  end

  def self.other_statuses(username)
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "1.1/statuses/user_timeline.json",
       :query_values => { :count => 20,
         :screen_name => username
       }

    ).to_s
    response = JSON.parse(EndUser::access_token.get(url).body)
    puts "#{username} statuses:\n\n"
    response.each do |message|
      Status.new(message['user']['screen_name'], message['text']).show
    end
  end

  def statuses(count = 10)
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "1.1/statuses/user_timeline.json",
       :query_values => { :count => count}

    ).to_s
    response = JSON.parse(EndUser::access_token.get(url).body)
    puts "#{@username} statuses:\n\n"
    response.each do |message|
      Status.new(message['user']['screen_name'], message['text']).show
    end
  end
end


class EndUser < User
  @@access_token = nil

  def self.access_token
    @@access_token
  end

  def self.login(username)
    # get_token.
    @@current_user = username
    # later, check if username matches file
    @@access_token = self.get_token('twit_token')

  end

  def timeline
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "1.1/statuses/home_timeline.json",
       :query_values => {:count => 20 }
    ).to_s
    response = JSON.parse(EndUser::access_token.get(url).body)

    puts "#{@username} timeline:\n\n"
    response.each do |message|
      Status.new(message['user']['screen_name'], message['text']).show
    end
    puts "\n\n"

  end

  def dm(target_user, message)
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "1.1/direct_messages/new.json",
       :query_values => {:text => message,
         :screen_name => target_user
       }
    ).to_s
    response = JSON.parse(EndUser::access_token.post(url).body)
    puts "DM sent to #{target_user}:"
    puts "Message:\n#{response['text']}"
  end

  def tweet(message)
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "1.1/statuses/update.json",
       :query_values => {:status => message}
    ).to_s
    response = JSON.parse(EndUser::access_token.post(url).body)
    puts "Tweet:\n#{response['text']}"
  end

  private

  def self.request_access_token
    request_token = CONSUMER.get_request_token
    authorize_url = request_token.authorize_url
    puts "Go to this URL: #{authorize_url}"
    Launchy.open(authorize_url)

    puts "Login, and type your verification code in"
    oauth_verifier = gets.chomp
    access_token = request_token.get_access_token(
        :oauth_verifier => oauth_verifier)
    access_token
  end

  def self.get_token(token_file)
    if File.exist?(token_file)
      File.open(token_file) { |f| YAML.load(f) }
    else
      access_token = self.request_access_token
      File.open(token_file, "w") { |f| YAML.dump(access_token, f) }

      access_token
    end
  end
end

class Status
  attr_reader :user
  # able to call status.user
  def initialize(user, status_message)
    @user = user
    @status_message = status_message
  end

  def show
    puts "User: #{@user}".ljust(25) + @status_message
  end
end

EndUser::login('Rich_Wallett')
user = EndUser.new('Rich_Wallett')
#user.tweet('Test tweet from TWIT by @kdavh and @rich_wallett.  #AppAcademy #Ruby #Hashtags')
#user.timeline
#user.statuses
#user.dm('kdavh', 'Test23')
User.other_statuses('kdavh')


#p EndUser::access_token.get("http://api.twitter.com/1.1/statuses/user_timeline.json").body