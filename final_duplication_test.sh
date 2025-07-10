#\!/bin/bash

BASE_URL="https://chat-29bz.onrender.com"

echo "=== Final Duplication Test ==="

# Create sessions
COOKIE_A=$(mktemp)
COOKIE_B=$(mktemp)

# Login
curl -s -c "$COOKIE_A" "$BASE_URL/login" > /dev/null
CSRF_A=$(curl -s -b "$COOKIE_A" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
curl -s -b "$COOKIE_A" -c "$COOKIE_A" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF_A" \
  -d "session[name]=FinalTestA&session[email]=finaltesta@example.com" > /dev/null

curl -s -c "$COOKIE_B" "$BASE_URL/login" > /dev/null
CSRF_B=$(curl -s -b "$COOKIE_B" "$BASE_URL/login" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
curl -s -b "$COOKIE_B" -c "$COOKIE_B" -X POST "$BASE_URL/login" \
  -H "X-CSRF-Token: $CSRF_B" \
  -d "session[name]=FinalTestB&session[email]=finaltestb@example.com" > /dev/null

# Get initial state
ROOM_HTML=$(curl -s -b "$COOKIE_A" "$BASE_URL/chat_rooms/1")
INITIAL=$(echo "$ROOM_HTML" | grep -c "data-message-id")
echo "Initial messages: $INITIAL"

# Extract IDs before
echo "$ROOM_HTML" | grep -o 'data-message-id="[^"]*"' | tail -5 > before_ids.txt

# Test 1: Rapid fire from same user
echo "Test 1: Rapid messages from same user..."
CSRF_ROOM=$(echo "$ROOM_HTML" | grep 'csrf-token' | sed -n 's/.*content="\([^"]*\)".*/\1/p')
for i in 1 2 3; do
    curl -s -b "$COOKIE_A" -X POST "$BASE_URL/chat_rooms/1/messages" \
      -H "X-CSRF-Token: $CSRF_ROOM" \
      -H "Accept: text/vnd.turbo-stream.html" \
      -d "message[content]=Rapid_${i}" > /dev/null
done

sleep 2

# Test 2: Alternating messages
echo "Test 2: Alternating messages..."
curl -s -b "$COOKIE_B" -X POST "$BASE_URL/chat_rooms/1/messages" \
  -H "X-CSRF-Token: $CSRF_ROOM" \
  -H "Accept: text/vnd.turbo-stream.html" \
  -d "message[content]=Alt_B1" > /dev/null

curl -s -b "$COOKIE_A" -X POST "$BASE_URL/chat_rooms/1/messages" \
  -H "X-CSRF-Token: $CSRF_ROOM" \
  -H "Accept: text/vnd.turbo-stream.html" \
  -d "message[content]=Alt_A1" > /dev/null

sleep 3

# Check final state
FINAL_HTML=$(curl -s -b "$COOKIE_A" "$BASE_URL/chat_rooms/1")
FINAL=$(echo "$FINAL_HTML" | grep -c "data-message-id")
echo "Final messages: $FINAL (Expected: $((INITIAL + 5)))"

# Check for duplicates
echo "Checking for duplicate IDs..."
echo "$FINAL_HTML" | grep -o 'data-message-id="[^"]*"' | sort | uniq -c | grep -v "1 data" || echo "✅ No duplicates found"

# Show last few messages
echo "Last 5 message IDs:"
echo "$FINAL_HTML" | grep -o 'data-message-id="[^"]*"' | tail -5

rm -f "$COOKIE_A" "$COOKIE_B" before_ids.txt
