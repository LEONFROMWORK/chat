// Chat Application Testing Script
// This script tests for message duplication issues

const TEST_URL = 'https://chat-29bz.onrender.com/';

// Test configuration
const TEST_CONFIG = {
    userA: {
        name: 'Test User A',
        email: 'testusera@example.com'
    },
    userB: {
        name: 'Test User B',
        email: 'testuserb@example.com'
    },
    messages: [
        'Hello from User A',
        'Hi from User B',
        'How are you?',
        'I am doing well, thanks!',
        'Quick message 1',
        'Quick message 2',
        'Quick message 3'
    ]
};

// Test results tracking
const testResults = {
    duplicatedMessages: [],
    uniqueMessageIds: new Set(),
    errors: [],
    observations: []
};

console.log(`
===========================================
Chat Application Duplication Test
URL: ${TEST_URL}
===========================================

This test requires manual interaction with the web application.
Please follow these steps:

1. Open two browser windows/tabs (or use incognito mode for the second)
2. Navigate to ${TEST_URL} in both windows
3. Log in as different users:
   - Window 1: ${TEST_CONFIG.userA.email}
   - Window 2: ${TEST_CONFIG.userB.email}

4. Once logged in, join the same chat room in both windows

5. Run the following tests and observe:

TEST 1: Alternate Messaging
---------------------------
- From User A, send: "${TEST_CONFIG.messages[0]}"
- From User B, send: "${TEST_CONFIG.messages[1]}"
- From User A, send: "${TEST_CONFIG.messages[2]}"
- From User B, send: "${TEST_CONFIG.messages[3]}"

Observe:
□ Are messages appearing only once?
□ Do both users see all messages?
□ Are message IDs unique (check browser console)?

TEST 2: Rapid Messaging
-----------------------
Send these messages quickly (< 1 second apart):
- From User A: "${TEST_CONFIG.messages[4]}"
- From User A: "${TEST_CONFIG.messages[5]}"
- From User A: "${TEST_CONFIG.messages[6]}"

Observe:
□ Do any messages appear twice?
□ Are all messages received in order?
□ Any console errors?

TEST 3: Idle Period Testing
---------------------------
1. Wait 20 seconds without sending messages
2. From User B, send: "Message after idle period"
3. Wait another 10 seconds
4. From User A, send: "Response after delay"

Observe:
□ Do messages appear duplicated after idle?
□ Is the connection maintained?
□ Any reconnection messages?

THINGS TO CHECK:
================
1. Open browser Developer Console (F12)
2. Check Network tab for WebSocket connections
3. Look for any errors in Console
4. Monitor for duplicate message IDs
5. Check if messages have unique identifiers

RECORDING RESULTS:
==================
Please note:
- Any duplicated messages (content and ID)
- Console errors or warnings
- Network disconnections/reconnections
- Unusual behavior or delays
`);

// Helper function to generate test checklist
console.log(`
DUPLICATION CHECKLIST:
======================
For each message sent, record:
[ ] Message appears only once in sender's view
[ ] Message appears only once in receiver's view
[ ] Message has unique ID (if visible)
[ ] No console errors when sending
[ ] No network errors in DevTools

If duplication occurs, note:
- Which user sent the message
- Message content
- How many times it appeared
- Any error messages
- Time between duplicates
`);