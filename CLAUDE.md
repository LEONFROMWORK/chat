# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Ruby on Rails chat application with Tailwind CSS for styling. The app provides basic chat room functionality with user authentication.

## Development Commands

**Start the development server:**
```bash
bin/dev
```
This runs both Rails server and Tailwind CSS build process.

**Database commands:**
```bash
rails db:create     # Create the database
rails db:migrate    # Run migrations
rails db:seed       # Seed the database (if seeds are added)
```

**Rails console:**
```bash
rails console       # Interactive Ruby console with app loaded
```

## Architecture

The application follows standard Rails MVC architecture:

- **Models**: User, ChatRoom, Message
  - Users can have many messages
  - ChatRooms can have many messages
  - Messages belong to both User and ChatRoom

- **Controllers**:
  - SessionsController: Handles user login/logout
  - ChatRoomsController: Lists rooms and shows individual chat rooms
  - MessagesController: Handles message creation

- **Authentication**: Simple session-based authentication
  - No password required (email-based)
  - Creates user automatically on first login

## Key Features

- Multiple chat rooms
- Real-time message display using Action Cable WebSockets
- User authentication
- Responsive Tailwind CSS design

## Next Steps for Enhancement

- Add user avatars
- Add message timestamps formatting
- Add room creation functionality
- Add message editing/deletion
- Add user presence indicators
