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

  def self.statuses_of(username)
    url = User.prep_url('statuses/user_timeline',
      {count: 15, screen_name: username})
    self.show( JSON.parse(EndUser::access_token.get(url).body) )
  end

  def statuses
    url = User.prep_url('statuses/user_timeline', {count: 15})
    User.show( JSON.parse(EndUser::access_token.get(url).body) )
  end

  protected

  def self.show(response)
    if response[0]
      puts "#{response[0]['user']['screen_name']} statuses:\n\n"
      response.each do |message|
        Status.new(message['user']['screen_name'], message['text']).show
      end
    end
  end

  def self.prep_url(path, query_val_hash)
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "1.1/#{path}.json",
       :query_values => query_val_hash
    ).to_s
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
    url = User.prep_url('statuses/home_timeline', {count: 20})
    User.show( JSON.parse(EndUser::access_token.get(url).body) )
  end

  def dm(target_user, message)
    url = User.prep_url('direct_messages/new',
      {text: message, screen_name: target_user})

    response = JSON.parse(EndUser::access_token.post(url).body)
    inform_of(response, target_user)
  end

  def tweet(message)
    url = User.prep_url('statuses/update', {status: message} )
    response = JSON.parse(EndUser::access_token.post(url).body)
    inform_of(response)
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

  def inform_of(response, target_user = nil)
    if response['text'].nil?
      puts response['errors'][0]['message']
    else
      target_user ? puts("DM to #{target_user}") : puts("Tweet")
      puts "Sent:\n#{response['text']}"
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
user = EndUser.new('Rich_Wallett') #Ruby #Hashtags')
user.timeline
# user.statuses
# User.statuses_of('kdavh')
# user.tweet("Test tweet from TWIT 2. @kdavh @rich_wallet")
# user.dm('kdavh', 'test DM from TWIT, again, and once more...')
