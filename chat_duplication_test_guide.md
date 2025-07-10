# Chat Application Message Duplication Test Guide

**Application URL:** https://chat-29bz.onrender.com/  
**Test Date:** 2025-07-10  
**Test Objective:** Identify message duplication issues

## Test Setup

### Required Tools
- 2 browser windows (use regular + incognito mode or 2 different browsers)
- Browser Developer Tools (F12)

### Test Accounts
- **User A:** testusera@example.com
- **User B:** testuserb@example.com

## Pre-Test Checklist
- [ ] Open Developer Console in both browser windows
- [ ] Enable Network tab monitoring
- [ ] Clear console before starting tests

## Test Scenarios

### Test 1: Basic Message Exchange
1. Both users join the same chat room
2. User A sends: "Hello from User A"
3. Wait 2 seconds
4. User B sends: "Hi from User B"
5. Wait 2 seconds
6. User A sends: "How are you?"
7. Wait 2 seconds
8. User B sends: "I am doing well, thanks!"

**Check for:**
- [ ] Each message appears only once
- [ ] Both users see all messages
- [ ] Message order is consistent
- [ ] No console errors

### Test 2: Rapid Fire Messages
Send these messages as quickly as possible (< 0.5s between each):

1. User A sends:
   - "Quick message 1"
   - "Quick message 2"
   - "Quick message 3"
   - "Quick message 4"
   - "Quick message 5"

**Check for:**
- [ ] No duplicate messages
- [ ] All messages received by User B
- [ ] Messages maintain order
- [ ] WebSocket connection stability

### Test 3: Concurrent Messaging
Both users send messages at the same time:

1. Count down 3, 2, 1...
2. Both users simultaneously send:
   - User A: "Simultaneous A"
   - User B: "Simultaneous B"

**Check for:**
- [ ] Both messages appear once
- [ ] No message loss
- [ ] No duplication

### Test 4: Idle Connection Test
1. Send no messages for 30 seconds
2. User A sends: "Message after long idle"
3. Wait 5 seconds
4. User B sends: "Response after idle"

**Check for:**
- [ ] Messages sent successfully after idle
- [ ] No duplication after reconnection
- [ ] Connection status indicators

### Test 5: Network Disruption (Optional)
1. User A: Open Network tab in DevTools
2. Send a message
3. Quickly toggle "Offline" mode on and off
4. Send another message

**Check for:**
- [ ] Message queuing behavior
- [ ] Duplicate sending after reconnection
- [ ] Error handling

## What to Monitor in DevTools

### Console Tab
Look for:
- JavaScript errors
- WebSocket connection messages
- Any warnings about duplicate IDs
- Failed API calls

### Network Tab
Monitor:
- WebSocket connections (filter by WS)
- Message frames being sent/received
- Connection drops or reconnections
- HTTP requests for message sending

### Specific Things to Note
1. **Message Structure:** Check if messages have unique IDs
2. **Timestamps:** Note if duplicates have same/different timestamps
3. **User Attribution:** Verify sender information is correct
4. **Event Listeners:** Look for multiple event handler registrations

## Recording Duplication Issues

When a duplication occurs, record:

```
Time: [timestamp]
Sender: [User A/B]
Message Content: [exact text]
Duplication Count: [how many times it appeared]
Location: [sender's view / receiver's view / both]
Message IDs: [if visible]
Console Errors: [copy any errors]
Network Activity: [describe any unusual patterns]
```

## Post-Test Analysis

1. Count total duplications found
2. Identify patterns:
   - Only after idle?
   - Only with rapid sending?
   - Specific to one user?
3. Check for correlation with:
   - Network events
   - Console errors
   - Specific user actions

## Example Bug Report Format

```
DUPLICATION ISSUE #1
====================
Scenario: Rapid message sending
User: User A
Message: "Quick message 3"
Appeared: 2 times in both views
Time between duplicates: ~100ms
Console Error: None
Network: WebSocket frame sent twice
Reproducible: Yes (3/3 attempts)
```