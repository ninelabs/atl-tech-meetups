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

class NilProcessor
  attr_reader :value
  def initialize(value)
    @value = value
  end
end

class DescriptionProcessor
  def initialize(value)
    @value = value
  end

  def value
    @processed_value ||= @value.split("\n")[0]
  end
end

COLUMNS = [ 
  {header: "Name", keys: ["name"]},
  {header: "URL", keys: ["link"]},
  {header: "Photo", keys: ["key_photo", "photo_link"]},
  {header: "Description", keys: ["plain_text_description"], processor: DescriptionProcessor},
  {header: "Members", keys: ["members"]}
]

HEADERS = COLUMNS.map { |c| c[:header] }
COLUMN_KEYS = COLUMNS.map { |c| c[:keys] }

def parse_meetup(meetup)
  COLUMNS.map { |c| parse_response_data(meetup, c[:keys], c[:processor]) }
end

def parse_response_data(data, keys, processor)
  return "" if data.nil?
  key = keys[0]
  other_keys = keys[1..-1]
  value = data[key]
  return parse_response_data(data[key], other_keys, processor) unless other_keys.empty?
  processor ||= NilProcessor
  processor.new(value).value
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
