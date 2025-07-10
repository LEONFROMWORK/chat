#!/usr/bin/env ruby

puts "=== Real-time Messaging Debug Script ==="
puts

# Check server
puts "1. Checking if server is running on port 3001..."
require 'net/http'
begin
  response = Net::HTTP.get_response(URI.parse('http://localhost:3001'))
  puts "   ✓ Server is running (status: #{response.code})"
rescue => e
  puts "   ✗ Server not running: #{e.message}"
  puts "   Please start the server with: bin/dev"
  exit 1
end

# Check Action Cable endpoint
puts "\n2. Checking Action Cable endpoint..."
begin
  uri = URI.parse('http://localhost:3001/cable')
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri)
  request['Connection'] = 'Upgrade'
  request['Upgrade'] = 'websocket'
  request['Sec-WebSocket-Version'] = '13'
  request['Sec-WebSocket-Key'] = 'dGhlIHNhbXBsZSBub25jZQ=='
  
  response = http.request(request)
  puts "   Response code: #{response.code}"
  puts "   Upgrade header: #{response['upgrade']}"
  
  if response.code == '101' || response['upgrade'] == 'websocket'
    puts "   ✓ WebSocket endpoint is available"
  else
    puts "   ✗ WebSocket endpoint not responding correctly"
    puts "   This might be normal if authentication is required"
  end
rescue => e
  puts "   ✗ Error: #{e.message}"
end

# Instructions for manual testing
puts "\n3. Manual Testing Instructions:"
puts "   a) Restart the Rails server to apply configuration changes:"
puts "      - Stop the server (Ctrl+C)"
puts "      - Run: bin/dev"
puts
puts "   b) Open two browser windows:"
puts "      - Window 1: Go to http://localhost:3001 and login"
puts "      - Window 2: Open incognito/private window, go to http://localhost:3001 and login with different user"
puts
puts "   c) In both windows, go to the same chat room"
puts
puts "   d) Send a message from Window 1"
puts
puts "   e) Check if the message appears in Window 2 without refreshing"
puts
puts "\n4. Check browser console for errors:"
puts "   - Open Developer Tools (F12)"
puts "   - Go to Console tab"
puts "   - Look for WebSocket connection errors"
puts "   - Look for messages like 'Connected to ChatRoomChannel'"
puts
puts "\n5. Common issues:"
puts "   - Server not restarted after config changes"
puts "   - User not logged in (Action Cable requires authentication)"
puts "   - JavaScript errors preventing connection"
puts "   - CORS/origin restrictions"