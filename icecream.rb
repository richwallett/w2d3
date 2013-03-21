#Geocoding - get user's location
#Place - Find nearby ice cream
#Directions - Find path between location and ice cream

require 'addressable/uri'
require 'rest-client'
require 'nokogiri'
require 'open-uri'
require 'json'
require './secrets.rb'

my_location='160+folsom+st+san+francisco+ca'

def get_geolocation(my_location)
  url = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "maps/api/geocode/json",
     :query_values => {:address => my_location,
       :sensor => true
     }
   ).to_s

  response = JSON.parse(RestClient.get(url))

  lat = response['results'][0]['geometry']['location']['lat'].to_s
  lng = response['results'][0]['geometry']['location']['lng'].to_s
  [lat,lng]
end

def get_places(hash)
  default_hash = {:radius => 100, :search => 'ice cream'}
  hash.merge!(default_hash)
  url = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "maps/api/place/nearbysearch/json",
     :query_values => {
           :query => hash[:search],
           :sensor => true,
           :radius => hash[:radius],
           :types => 'food',
           :location => hash[:location].join(','),
           :key => maps_key
     }
   ).to_s

  response = JSON.parse(RestClient.get(url))
  places_array = []
  counter = 0
  response['results'].each do |result|
    break if counter > 5
    places_array << [result['name'], result['vicinity']]
    counter += 1
  end
  places_array
end

def get_directions(my_location, places_array)
  directions_array = []
  places_array.each do |place|
    url = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/directions/json",
      :query_values => {
           :origin => my_location,
           :destination => place[1],
           :sensor => true
      }
    ).to_s

    response = JSON.parse(RestClient.get(url))
    place_directions = []
    response['routes'][0]['legs'].each do |leg|
      leg['steps'].each do |step|
        parsed_html = Nokogiri::HTML(step['html_instructions']).text
        place_directions << parsed_html
      end
    end
    puts
    directions_array << place_directions
  end
  directions_array
end

def print_directions(places_array, directions_array)
  (0...(places_array.length)).each do |index|
    puts "Directions to: #{places_array[index][0]}, at #{places_array[index][1]}"
    directions_array[index].each do |step|
      puts step
    end
    puts
  end
end



lat_lng = get_geolocation(my_location)
places_array = get_places(:location=> lat_lng)
directions_array = get_directions(my_location, places_array)
print_directions(places_array, directions_array)



#
# https://maps.googleapis.com/maps/api/place/nearbysearch/json?
# location=-33.8670522,151.1957362&radius=500&
# types=food&name=harbour&sensor=false&key=AddYourOwnKeyHere
