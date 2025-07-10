#\!/bin/bash

# Production URL
BASE_URL="https://chat-29bz.onrender.com"

# Create two sessions
echo "Creating session for User A..."
COOKIE_A=$(mktemp)
curl -s -c "$COOKIE_A" "$BASE_URL/login" > /dev/null

echo "Creating session for User B..."
COOKIE_B=$(mktemp)
curl -s -c "$COOKIE_B" "$BASE_URL/login" > /dev/null

# Login as User A
echo "Logging in as TestUserA..."
CSRF_A=$(curl -s -b "$COOKIE_A" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
curl -s -b "$COOKIE_A" -c "$COOKIE_A" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF_A" \
  -d "session[name]=TestUserA&session[email]=testusera@example.com" > /dev/null

# Login as User B
echo "Logging in as TestUserB..."
CSRF_B=$(curl -s -b "$COOKIE_B" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
curl -s -b "$COOKIE_B" -c "$COOKIE_B" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF_B" \
  -d "session[name]=TestUserB&session[email]=testuserb@example.com" > /dev/null

# Get chat room page and check for duplicates
echo "Accessing chat room..."
ROOM_HTML=$(curl -s -b "$COOKIE_A" "$BASE_URL/chat_rooms/1")

# Check which controller is being used
if echo "$ROOM_HTML" | grep -q "data-controller=\"chat-room-optimized\""; then
    echo "Using optimized controller"
else
    echo "Using basic controller"
fi

# Count existing messages
EXISTING_COUNT=$(echo "$ROOM_HTML" | grep -c "data-message-id")
echo "Existing messages: $EXISTING_COUNT"

# Send a test message from User A
echo "Sending message from User A..."
CSRF_A_ROOM=$(echo "$ROOM_HTML" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
MSG_TIME=$(date +%s)
curl -s -b "$COOKIE_A" -X POST "$BASE_URL/chat_rooms/1/messages" \
  -H "X-CSRF-Token: $CSRF_A_ROOM" \
  -H "Accept: text/vnd.turbo-stream.html, text/html" \
  -d "message[content]=Test_${MSG_TIME}_UserA" > /dev/null

sleep 2

# Check for duplicates after sending
echo "Checking for duplicates..."
ROOM_AFTER=$(curl -s -b "$COOKIE_B" "$BASE_URL/chat_rooms/1")
NEW_COUNT=$(echo "$ROOM_AFTER" | grep -c "data-message-id")
echo "Messages after sending: $NEW_COUNT"

# Check for duplicate IDs
echo "Checking for duplicate message IDs..."
echo "$ROOM_AFTER" | grep -o 'data-message-id="[^"]*"' | sort | uniq -d

# Clean up
rm -f "$COOKIE_A" "$COOKIE_B"
