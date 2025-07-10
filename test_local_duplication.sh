#\!/bin/bash

# Local URL
BASE_URL="http://localhost:3001"

# Create two sessions
echo "Creating two local sessions..."
COOKIE_A=$(mktemp)
COOKIE_B=$(mktemp)

# Login as User A
echo "Logging in as LocalUserA..."
curl -s -c "$COOKIE_A" "$BASE_URL/login" > /dev/null
CSRF_A=$(curl -s -b "$COOKIE_A" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
curl -s -b "$COOKIE_A" -c "$COOKIE_A" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF_A" \
  -d "session[name]=LocalUserA&session[email]=localusera@example.com" > /dev/null

# Login as User B
echo "Logging in as LocalUserB..."
curl -s -c "$COOKIE_B" "$BASE_URL/login" > /dev/null
CSRF_B=$(curl -s -b "$COOKIE_B" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
curl -s -b "$COOKIE_B" -c "$COOKIE_B" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF_B" \
  -d "session[name]=LocalUserB&session[email]=localuserb@example.com" > /dev/null

# Check initial state
echo "Checking initial state..."
ROOM_HTML=$(curl -s -b "$COOKIE_A" "$BASE_URL/chat_rooms/1")
INITIAL_COUNT=$(echo "$ROOM_HTML" | grep -c "data-message-id")
echo "Initial messages: $INITIAL_COUNT"

# Send multiple messages rapidly
echo "Sending rapid messages..."
CSRF_A_ROOM=$(echo "$ROOM_HTML" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')

for i in 1 2 3; do
    echo "Sending message $i from UserA..."
    curl -s -b "$COOKIE_A" -X POST "$BASE_URL/chat_rooms/1/messages" \
      -H "X-CSRF-Token: $CSRF_A_ROOM" \
      -H "Accept: text/vnd.turbo-stream.html, text/html" \
      -d "message[content]=LocalTest_${i}_UserA" > /dev/null
    sleep 0.5
done

# Check for duplicates
sleep 2
echo "Checking final state..."
FINAL_HTML=$(curl -s -b "$COOKIE_A" "$BASE_URL/chat_rooms/1")
FINAL_COUNT=$(echo "$FINAL_HTML" | grep -c "data-message-id")
echo "Final messages: $FINAL_COUNT (Expected: $((INITIAL_COUNT + 3)))"

# Check for duplicate IDs
echo "Checking for duplicate message IDs..."
DUPLICATES=$(echo "$FINAL_HTML" | grep -o 'data-message-id="[^"]*"' | sort | uniq -d)
if [ -z "$DUPLICATES" ]; then
    echo "✅ No duplicate IDs found"
else
    echo "❌ Duplicate IDs found:"
    echo "$DUPLICATES"
fi

# Clean up
rm -f "$COOKIE_A" "$COOKIE_B"
