require 'addressable/uri'
require 'rest-client'
require 'nokogiri'
require 'open-uri' # what's this for?
require 'json'
require 'oauth'
require './secrets.rb'




class User
  def authenticate
    url = Addressable::URI.new(
       :scheme => "https",
       :host => "twitter.com",
       :path => "oauth/request_token"
       # :query_values => {:address => my_location,
#          :sensor => true
       # }
     ).to_s

    response = JSON.parse(RestClient.get(url))
    p response
  end

  def dm
  end
  # able to call user.statuses
end

class Status
  # able to call status.user
end

class DM

end

class Tweets

end

u = User.new
u.authenticate