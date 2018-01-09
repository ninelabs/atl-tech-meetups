require 'net/http'
require 'json'
require 'csv'

API_ROOT = "https://api.meetup.com/find/groups?"

PARAMETERS = {
  zip:  '30363',
  radius: '50',
  category: '34',
  order:  'members',
  fields: 'key_photo,plain_text_description',
  text_format: 'plain',
  fallback_suggestions: 'false',
  key: ENV['MEETUP_API_KEY']
}

COLUMNS = [ 
  {header: "Name", keys: ["name"]},
  {header: "URL", keys: ["link"]},
  {header: "Photo", keys: ["key_photo", "photo_link"]},
  {header: "Description", keys: ["plain_text_description"]},
  {header: "Members", keys: ["members"]}
]

HEADERS = COLUMNS.map { |c| c[:header] }
COLUMN_KEYS = COLUMNS.map { |c| c[:keys] }

def parse_meetup(meetup)
  COLUMN_KEYS.map { |c| parse_response_data(meetup, c) }
end

def parse_response_data(data, keys)
  return "" if data.nil?
  key = keys[0]
  other_keys = keys[1..-1]
  value = data[key]

  other_keys.empty? ? value : parse_response_data(value, other_keys)
end

param_arrays = PARAMETERS.map { |k, v| [k, v] }
param_string = URI.encode_www_form(param_arrays)
request_uri = URI("#{API_ROOT}#{param_string}")
response = Net::HTTP.get(request_uri)

json_response = JSON.parse(response)
unless json_response.is_a? Array
  raise ArgumentError, json_response.to_s
end

csv = CSV.generate do |csv|
  csv << HEADERS 
  json_response.each do |meetup|
    csv << parse_meetup(meetup)
  end
end
puts csv
