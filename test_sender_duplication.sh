#\!/bin/bash

BASE_URL="https://chat-29bz.onrender.com"

echo "=== Testing Sender Duplication ==="

# Create session
COOKIE=$(mktemp)
curl -s -c "$COOKIE" "$BASE_URL/login" > /dev/null
CSRF=$(curl -s -b "$COOKIE" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')

# Login
curl -s -b "$COOKIE" -c "$COOKIE" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF" \
  -d "session[name]=SenderTest&session[email]=sendertest@example.com" > /dev/null

echo "Logged in as SenderTest"

# Get initial state
ROOM_HTML=$(curl -s -b "$COOKIE" "$BASE_URL/chat_rooms/1")
INITIAL=$(echo "$ROOM_HTML" | grep -c "data-message-id")
echo "Initial messages: $INITIAL"

# Get CSRF token for messages
CSRF_ROOM=$(echo "$ROOM_HTML" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')

# Send a unique message
UNIQUE_MSG="Test_$(date +%s)_Sender"
echo "Sending message: $UNIQUE_MSG"

curl -s -b "$COOKIE" -X POST "$BASE_URL/chat_rooms/1/messages" \
  -H "X-CSRF-Token: $CSRF_ROOM" \
  -H "Accept: text/vnd.turbo-stream.html, text/html" \
  -d "message[content]=$UNIQUE_MSG" > /dev/null

sleep 3

# Check final state
FINAL_HTML=$(curl -s -b "$COOKIE" "$BASE_URL/chat_rooms/1")
FINAL=$(echo "$FINAL_HTML" | grep -c "data-message-id")
echo "Final messages: $FINAL (Expected: $((INITIAL + 1)))"

# Count occurrences of our unique message
OCCURRENCES=$(echo "$FINAL_HTML" | grep -c "$UNIQUE_MSG")
echo "Occurrences of '$UNIQUE_MSG': $OCCURRENCES"

if [ "$OCCURRENCES" -eq 1 ]; then
    echo "✅ No duplication - Message appears only once"
else
    echo "❌ Duplication detected - Message appears $OCCURRENCES times"
fi

# Check console recommendation
echo ""
echo "To debug in browser:"
echo "1. Open https://chat-29bz.onrender.com/chat_rooms/1"
echo "2. Open DevTools Console (F12)"
echo "3. Send a message and look for:"
echo "   - 'Own message ignored from broadcast:'"
echo "   - 'Duplicate message ignored:'"

rm -f "$COOKIE"
