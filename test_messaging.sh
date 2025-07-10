#!/bin/bash

# Test Rails Chat Application Messaging Flow

echo "=== Testing Rails Chat Application Messaging ==="
echo

# Clean up old cookies
rm -f cookies.txt

# Step 1: Get the login page and extract CSRF token
echo "Step 1: Getting CSRF token from login page..."
CSRF_TOKEN=$(curl -s http://localhost:3001/login -c cookies.txt | grep 'name="authenticity_token"' | grep -v 'meta' | sed 's/.*value="\([^"]*\)".*/\1/' | head -1)
echo "CSRF Token: $CSRF_TOKEN"
echo

# Step 2: Login with the CSRF token
echo "Step 2: Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "authenticity_token=${CSRF_TOKEN}&session[name]=Test User&session[email]=test@example.com" \
  -b cookies.txt \
  -c cookies.txt \
  -w "\nHTTP_CODE:%{http_code}" \
  -L)

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "Login HTTP Response Code: $HTTP_CODE"

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "Login successful!"
else
  echo "Login failed!"
  echo "$LOGIN_RESPONSE"
  exit 1
fi
echo

# Step 3: Get the chat room page and extract new CSRF token
echo "Step 3: Getting CSRF token from chat room page..."
CHAT_CSRF=$(curl -s http://localhost:3001/chat_rooms/1 -b cookies.txt -c cookies.txt | grep 'name="csrf-token"' | sed 's/.*content="\([^"]*\)".*/\1/')
echo "Chat CSRF Token: $CHAT_CSRF"
echo

# Step 4: Post a message
echo "Step 4: Posting a message..."
MESSAGE_CONTENT="Hello from curl test at $(date)"
echo "Message content: $MESSAGE_CONTENT"

# Try with form data and X-CSRF-Token header
RESPONSE=$(curl -s -X POST http://localhost:3001/chat_rooms/1/messages \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-CSRF-Token: ${CHAT_CSRF}" \
  -d "message[content]=${MESSAGE_CONTENT}" \
  -b cookies.txt \
  -c cookies.txt \
  -w "\nHTTP_CODE:%{http_code}" \
  -L)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "Message Post HTTP Response Code: $HTTP_CODE"

if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]]; then
  echo "Message posted successfully!"
else
  echo "Failed to post message"
  echo "Response:"
  echo "$RESPONSE" | head -20
fi
echo

# Step 5: Verify the message was created
echo "Step 5: Checking if message was created..."
curl -s http://localhost:3001/chat_rooms/1 -b cookies.txt | grep -C2 "$MESSAGE_CONTENT" > /dev/null
if [ $? -eq 0 ]; then
  echo "Message found in chat room!"
else
  echo "Message not found in chat room"
  
  # Let's check using Rails console
  echo "Checking database directly..."
  rails runner "puts Message.last(5).map { |m| \"#{m.created_at}: #{m.content}\" }.join('\n')"
fi

echo
echo "=== Test Complete ==="