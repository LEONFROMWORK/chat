#!/usr/bin/env ruby

require 'net/http'
require 'uri'

# Test if Action Cable WebSocket endpoint is accessible
uri = URI.parse('http://localhost:3001/cable')
response = Net::HTTP.get_response(uri)

puts "Testing Action Cable endpoint at #{uri}"
puts "Response Code: #{response.code}"
puts "Response Message: #{response.message}"
puts "Headers: #{response.to_hash.inspect}"

# Check if upgrade header is present (indicates WebSocket support)
if response['upgrade'] == 'websocket'
  puts "✓ WebSocket upgrade header present"
else
  puts "✗ WebSocket upgrade header not found"
end