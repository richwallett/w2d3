require 'launchy'
require 'oauth'
require 'yaml'
require './secrets.rb'

# "consumer" in OAuth terminology means "client" in our discussion.
CONSUMER_KEY = "consumer_key_from_service"
CONSUMER_SECRET = "consumer_secret_from_service"

CONSUMER = OAuth::Consumer.new(
  CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")

# ask the user to authorize the application
def request_access_token
  # send user to twitter URL to authorize application
  request_token = CONSUMER.get_request_token
  authorize_url = request_token.authorize_url
  puts "Go to this URL: #{authorize_url}"
  # launchy is a gem that opens a browser tab for us
  Launchy.open(authorize_url)

  # because we don't use a redirect URL; user will receive an "out of
  # band" verification code that the application may exchange for a
  # key; ask user to give it to us
  puts "Login, and type your verification code in"
  oauth_verifier = gets.chomp

  # ask the oauth library to give us an access token, which will allow
  # us to make requests on behalf of this user
  access_token = request_token.get_access_token(
      :oauth_verifier => oauth_verifier)
end

# fetch a user's timeline
def user_timeline(access_token)
  # the access token class has methods `get` and `post` to make
  # requests in the same way as RestClient, except that these will be
  # authorized. The token takes care of the crypto for us :-)
  access_token.get("http://api.twitter.com/1.1/statuses/user_timeline.json").body
end

def get_token(token_file)
  # We can serialize token to a file, so that future requests don't need
  # to be reauthorized.

  if File.exist?(token_file)
    File.open(token_file) { |f| YAML.load(f) }
  else
    access_token = request_access_token
    File.open(token_file, "w") { |f| YAML.dump(access_token, f) }

    access_token
  end
end