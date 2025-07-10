# Rails 채팅 애플리케이션 개발 가이드

이 문서는 Ruby on Rails로 실시간 채팅 기능을 개발하면서 겪은 문제들과 해결 방법을 정리한 가이드입니다.

## 목차
1. [프로젝트 초기 설정](#프로젝트-초기-설정)
2. [권장 프로젝트 구조](#권장-프로젝트-구조)
3. [주요 문제점과 해결 방법](#주요-문제점과-해결-방법)
4. [Action Cable 실시간 채팅 구현](#action-cable-실시간-채팅-구현)
5. [배포 시 고려사항](#배포-시-고려사항)
6. [체크리스트](#체크리스트)

## 프로젝트 초기 설정

### 1. Rails 애플리케이션 생성
```bash
rails new chat_app
cd chat_app
```

### 2. 필수 Gem 추가
```ruby
# Gemfile
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'redis' # Production에서 Action Cable 사용 시 필요
```

### 3. 프로젝트 생성 시 권장 옵션
```bash
# PostgreSQL 사용
rails new chat_app --database=postgresql

# CSS 프레임워크 없이 (Tailwind CDN 사용 예정)
rails new chat_app --skip-asset-pipeline

# 테스트 프레임워크 지정
rails new chat_app --test-framework=minitest
```

## 권장 프로젝트 구조

### 필수 디렉토리 및 파일
```
app/
├── channels/
│   ├── application_cable/
│   │   ├── channel.rb
│   │   └── connection.rb      # 중요: WebSocket 인증
│   └── chat_room_channel.rb   # 실시간 메시징 채널
├── controllers/
│   ├── chat_rooms_controller.rb
│   ├── messages_controller.rb
│   └── sessions_controller.rb
├── javascript/
│   ├── controllers/
│   │   └── chat_room_controller.js  # Stimulus 컨트롤러
│   └── channels/
│       └── consumer.js
├── models/
│   ├── user.rb
│   ├── chat_room.rb
│   └── message.rb
└── views/
    ├── chat_rooms/
    │   ├── index.html.erb
    │   └── show.html.erb
    ├── messages/
    │   ├── _message.html.erb
    │   └── create.turbo_stream.erb  # 중요: Turbo Stream 응답
    └── layouts/
        └── application.html.erb
```

### 설정 파일 체크리스트
- [ ] `config/routes.rb` - Action Cable 마운트 확인
- [ ] `config/cable.yml` - 어댑터 설정
- [ ] `config/importmap.rb` - JavaScript 모듈 설정
- [ ] `config/environments/*.rb` - Action Cable 허용 도메인

### 4. 모델 구조
```ruby
# User 모델
class User < ApplicationRecord
  has_many :messages, dependent: :destroy
end

# ChatRoom 모델
class ChatRoom < ApplicationRecord
  has_many :messages, dependent: :destroy
end

# Message 모델
class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  
  scope :recent, -> { order(created_at: :desc).limit(50) }
end
```

## 주요 문제점과 해결 방법

### 1. Render 배포 시 PostgreSQL 연결 오류

**문제**: Render의 무료 플랜에서 PostgreSQL 연결이 실패하는 경우

**해결 방법**: SQLite3로 전환
```ruby
# Gemfile
gem 'sqlite3', '>= 2.4'

# config/database.yml
production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

### 2. Rails Credentials 문제

**문제**: `ActiveSupport::MessageEncryptor::InvalidMessage` 오류

**원인**: 
- credentials.yml.enc와 master.key 불일치
- Render에 잘못된 RAILS_MASTER_KEY 설정

**해결 방법**:
```bash
# 기존 credentials 삭제
rm config/credentials.yml.enc

# 새로운 credentials 생성
EDITOR="vi" bin/rails credentials:edit

# master.key 내용 확인
cat config/master.key

# Render 환경 변수에 정확한 RAILS_MASTER_KEY 설정
```

### 3. Solid 관련 Gem 오류

**문제**: solid_cable, solid_cache, solid_queue gem이 배포 실패 원인

**해결 방법**:
```ruby
# Gemfile에서 제거
# gem "solid_cable"
# gem "solid_cache"
# gem "solid_queue"

# config/environments/production.rb 수정
config.cache_store = :memory_store
config.active_job.queue_adapter = :async

# config/cable.yml 단순화
production:
  adapter: async
```

### 4. Asset Pipeline 오류

**문제**: CSS/JS 파일이 404 오류 반환

**해결 방법**:
```ruby
# config/environments/production.rb
config.public_file_server.enabled = true

# bin/render-build.sh
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rake assets:clean RAILS_ENV=production
```

### 5. Tailwind CSS CDN 사용

**문제**: Asset pipeline 복잡성을 피하고 싶을 때

**해결 방법**:
```erb
<!-- app/views/layouts/application.html.erb -->
<script src="https://cdn.tailwindcss.com"></script>
```

## Action Cable 실시간 채팅 구현

### 1. 초기 구현의 문제점

**문제 1**: 페이지가 리로드되는 문제
- 원인: 폼 제출 시 기본 동작이 실행됨
- 해결: Turbo를 활용한 비동기 처리

**문제 2**: 상대방 메시지가 실시간으로 보이지 않음
- 원인: Action Cable 연결 및 인증 문제
- 해결: 올바른 WebSocket 설정 및 세션 인증

### 2. 올바른 Action Cable 구현

#### 2.1 Routes 설정
```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  # ... 다른 routes
end
```

#### 2.2 Action Cable 설정
```ruby
# config/environments/development.rb
config.action_cable.allowed_request_origins = [
  'http://localhost:3000',
  'ws://localhost:3000'
]

# config/environments/production.rb
config.action_cable.mount_path = '/cable'
config.action_cable.url = 'wss://your-app.onrender.com/cable'
config.action_cable.allowed_request_origins = [
  'https://your-app.onrender.com',
  'http://your-app.onrender.com'
]
```

#### 2.3 ApplicationCable 연결 인증
```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if cookies.encrypted[:_app_session].present?
        session_data = cookies.encrypted[:_app_session]
        session_user_id = session_data["user_id"] if session_data.is_a?(Hash)
        
        if session_user_id
          verified_user = User.find_by(id: session_user_id)
          return verified_user if verified_user
        end
      end
      
      reject_unauthorized_connection
    end
  end
end
```

#### 2.4 Channel 구현
```ruby
# app/channels/chat_room_channel.rb
class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    @chat_room = ChatRoom.find(params[:chat_room_id])
    stream_for @chat_room
  end

  def unsubscribed
    # 정리 작업
  end
end
```

#### 2.5 Stimulus Controller 사용
```javascript
// app/javascript/controllers/chat_room_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["messages", "messageInput"]
  static values = { chatRoomId: Number }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { 
        channel: "ChatRoomChannel",
        chat_room_id: this.chatRoomIdValue
      },
      {
        connected: () => {
          console.log('Connected to ChatRoomChannel')
        },

        received: (data) => {
          this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
          this.scrollToBottom()
        }
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  scrollToBottom() {
    if (this.messagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
```

#### 2.6 View 구현
```erb
<!-- app/views/chat_rooms/show.html.erb -->
<div data-controller="chat-room" data-chat-room-chat-room-id-value="<%= @chat_room.id %>">
  <div id="messages" data-chat-room-target="messages">
    <% @messages.each do |message| %>
      <%= render 'messages/message', message: message %>
    <% end %>
  </div>
  
  <%= form_with url: chat_room_messages_path(@chat_room), local: false do |f| %>
    <input type="text" name="message[content]" required>
    <button type="submit">Send</button>
  <% end %>
</div>
```

#### 2.7 Controller 구현
```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])
    @message = @chat_room.messages.build(message_params)
    @message.user = current_user
    
    if @message.save
      # Action Cable로 브로드캐스트
      ChatRoomChannel.broadcast_to(@chat_room, {
        message: render_to_string(partial: 'messages/message', 
                                 locals: { message: @message })
      })
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_room_path(@chat_room) }
      end
    end
  end
end
```

#### 2.8 Turbo Stream 응답
```erb
<!-- app/views/messages/create.turbo_stream.erb -->
<%= turbo_stream.append "messages", partial: "messages/message", 
                       locals: { message: @message } %>
<%= turbo_stream.after "messages" do %>
  <script>
    document.getElementById('messages').scrollTop = 
      document.getElementById('messages').scrollHeight;
    document.querySelector('input[name="message[content]"]').value = '';
  </script>
<% end %>
```

## 배포 시 고려사항

### 1. Render 배포 스크립트
```bash
#!/usr/bin/env bash
# bin/render-build.sh
set -o errexit

bundle install
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rake assets:clean RAILS_ENV=production
bundle exec rake db:create RAILS_ENV=production || true
bundle exec rake db:migrate RAILS_ENV=production
```

### 2. 환경 변수 설정
- `RAILS_MASTER_KEY`: config/master.key 내용
- `ACTION_CABLE_URL`: wss://your-app.onrender.com/cable (프로덕션)

### 3. 데이터베이스 설정
- 개발: SQLite3
- 프로덕션: SQLite3 또는 PostgreSQL (유료 플랜)

## 체크리스트

### 새 채팅 기능 구현 시 확인사항

- [ ] Rails 버전 확인 (Rails 7+ 권장)
- [ ] Turbo와 Stimulus 설치 확인
- [ ] Action Cable routes 마운트 확인
- [ ] WebSocket 연결을 위한 allowed origins 설정
- [ ] ApplicationCable::Connection 인증 구현
- [ ] Stimulus controller 생성 및 연결
- [ ] form_with에 `local: false` 옵션 추가
- [ ] Turbo Stream 응답 템플릿 생성
- [ ] 브라우저 콘솔에서 WebSocket 연결 확인
- [ ] 두 개의 브라우저로 실시간 테스트

### 디버깅 팁

1. **Rails 로그 확인**
   ```bash
   tail -f log/development.log | grep -E "ActionCable|ChatRoom"
   ```

2. **브라우저 콘솔 확인**
   - "Connected to ChatRoomChannel" 메시지 확인
   - WebSocket 연결 오류 확인

3. **네트워크 탭 확인**
   - WS (WebSocket) 연결 상태 확인
   - 101 Switching Protocols 응답 확인

### 일반적인 실수 방지

1. **Action Cable 설정 누락**
   - routes.rb에 mount 추가 필수
   - allowed_request_origins 설정 필수

2. **세션 인증 문제**
   - 쿠키 기반 세션 사용 시 encrypted cookie 확인
   - session key 이름 확인 (_app_session, _myapp_session 등)

3. **JavaScript 모듈 로딩**
   - importmap 설정 확인
   - channels 폴더 구조 확인

4. **Turbo 관련**
   - form_with의 local: false 옵션
   - turbo_stream 응답 템플릿 위치

## 마무리

이 가이드는 Rails로 실시간 채팅을 구현하면서 겪은 실제 문제들과 해결 방법을 정리한 것입니다. Action Cable과 Turbo를 함께 사용하면 강력한 실시간 기능을 구현할 수 있지만, 초기 설정과 디버깅에 주의가 필요합니다.

향후 프로젝트에서 이 가이드를 참조하여 같은 실수를 반복하지 않고 효율적으로 개발할 수 있기를 바랍니다.

---
작성일: 2025-07-10
프로젝트: Rails Chat Application with Tailwind CSS