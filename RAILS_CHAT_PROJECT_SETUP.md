# Rails 채팅 프로젝트 초기 설정 가이드

## 프로젝트 시작 전 체크리스트

### 환경 요구사항
- Ruby 3.0 이상
- Rails 7.0 이상 (Rails 8 권장)
- Node.js 16 이상
- PostgreSQL 또는 SQLite3

## 1. 프로젝트 생성 및 초기 구조

### 1.1 Rails 애플리케이션 생성
```bash
# 옵션 1: 기본 설정 (PostgreSQL)
rails new chat_app --database=postgresql

# 옵션 2: SQLite3 사용 (간단한 프로젝트)
rails new chat_app

# 옵션 3: API 모드가 아닌 풀스택 앱 확인
rails new chat_app --no-api

cd chat_app
```

### 1.2 권장 디렉토리 구조
```
chat_app/
├── app/
│   ├── channels/
│   │   ├── application_cable/
│   │   │   ├── channel.rb
│   │   │   └── connection.rb
│   │   └── chat_room_channel.rb
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── chat_rooms_controller.rb
│   │   ├── messages_controller.rb
│   │   └── sessions_controller.rb
│   ├── javascript/
│   │   ├── application.js
│   │   ├── channels/
│   │   │   ├── index.js
│   │   │   ├── consumer.js
│   │   │   └── chat_room_channel.js
│   │   └── controllers/
│   │       ├── application.js
│   │       ├── index.js
│   │       └── chat_room_controller.js
│   ├── models/
│   │   ├── user.rb
│   │   ├── chat_room.rb
│   │   └── message.rb
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb
│       ├── chat_rooms/
│       │   ├── index.html.erb
│       │   └── show.html.erb
│       ├── messages/
│       │   ├── _message.html.erb
│       │   └── create.turbo_stream.erb
│       └── sessions/
│           └── new.html.erb
├── config/
│   ├── cable.yml
│   ├── database.yml
│   ├── importmap.rb
│   └── routes.rb
├── bin/
│   └── render-build.sh
├── Gemfile
├── CLAUDE.md
└── README.md
```

## 2. 필수 Gem 설정

### 2.1 Gemfile 구성
```ruby
source "https://rubygems.org"

# 기본 Rails
gem "rails", "~> 8.0.0"
gem "sprockets-rails"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", ">= 4.0.1"

# 데이터베이스 (하나 선택)
gem "sqlite3", ">= 2.4"  # 개발/간단한 프로덕션
# gem "pg", "~> 1.1"     # PostgreSQL 사용 시

# Windows 호환성
gem "tzinfo-data", platforms: %i[ windows jruby ]

# 부팅 속도 향상
gem "bootsnap", require: false

# 이미지 처리 (필요시)
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

# 피해야 할 gem들 (Rails 8 기준)
# gem "solid_cable"   # 프로덕션 문제 발생 가능
# gem "solid_cache"   # 프로덕션 문제 발생 가능
# gem "solid_queue"   # 프로덕션 문제 발생 가능
```

## 3. 핵심 설정 파일

### 3.1 config/routes.rb
```ruby
Rails.application.routes.draw do
  # Action Cable 마운트 (필수!)
  mount ActionCable.server => '/cable'
  
  # 루트 경로
  root "chat_rooms#index"
  
  # 채팅방과 메시지
  resources :chat_rooms, only: [:index, :show] do
    resources :messages, only: [:create]
  end
  
  # 인증
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  
  # 헬스체크 (배포용)
  get "up" => "rails/health#show", as: :rails_health_check
end
```

### 3.2 config/cable.yml
```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: async  # 간단한 설정
  # adapter: redis  # Redis 사용 시
  # url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  # channel_prefix: chat_app_production
```

### 3.3 config/importmap.rb
```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
```

### 3.4 config/database.yml (SQLite3 버전)
```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: storage/development.sqlite3

test:
  <<: *default
  database: storage/test.sqlite3

production:
  <<: *default
  database: storage/production.sqlite3
```

## 4. 환경별 설정

### 4.1 config/environments/development.rb
```ruby
Rails.application.configure do
  # ... 기본 설정 ...
  
  # Action Cable 설정 (중요!)
  config.action_cable.allowed_request_origins = [
    'http://localhost:3000',
    'http://localhost:3001',
    'ws://localhost:3000',
    'ws://localhost:3001'
  ]
  
  # 개발 환경에서 Action Cable 로그 확인
  config.action_cable.logger = Logger.new(STDOUT)
end
```

### 4.2 config/environments/production.rb
```ruby
Rails.application.configure do
  # ... 기본 설정 ...
  
  # 정적 파일 서빙 (Render 등 PaaS 사용 시)
  config.public_file_server.enabled = true
  
  # Action Cable 설정
  config.action_cable.mount_path = '/cable'
  config.action_cable.url = ENV['ACTION_CABLE_URL'] || 'wss://your-app.com/cable'
  config.action_cable.allowed_request_origins = [
    'https://your-app.com',
    'http://your-app.com'
  ]
  
  # 캐시 스토어 (simple 설정)
  config.cache_store = :memory_store
  
  # 작업 큐 (simple 설정)
  config.active_job.queue_adapter = :async
end
```

## 5. 모델 생성 스크립트

### 5.1 초기 마이그레이션 생성
```bash
# User 모델
rails generate model User name:string email:string:uniq
rails generate migration AddIndexToUsersEmail

# ChatRoom 모델
rails generate model ChatRoom name:string

# Message 모델
rails generate model Message content:text user:references chat_room:references

# 마이그레이션 실행
rails db:create
rails db:migrate
```

### 5.2 모델 관계 설정
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :messages, dependent: :destroy
  
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end

# app/models/chat_room.rb
class ChatRoom < ApplicationRecord
  has_many :messages, dependent: :destroy
  
  validates :name, presence: true
end

# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  
  validates :content, presence: true
  
  scope :recent, -> { order(created_at: :desc).limit(50) }
  
  # 정렬된 메시지 반환
  def self.sorted
    order(:created_at)
  end
end
```

## 6. 컨트롤러 기본 구조

### 6.1 ApplicationController
```ruby
class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_user
    if !logged_in?
      flash[:alert] = "You must be logged in to perform that action"
      redirect_to login_path
    end
  end
end
```

## 7. JavaScript 초기 설정

### 7.1 app/javascript/application.js
```javascript
import "@hotwired/turbo-rails"
import "controllers"
import "channels"
```

### 7.2 app/javascript/channels/index.js
```javascript
// 채널을 자동으로 로드
import "./consumer"
```

### 7.3 app/javascript/controllers/index.js
```javascript
import { application } from "./application"

// 컨트롤러 자동 로드 설정
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

## 8. 배포 준비

### 8.1 bin/render-build.sh (Render 배포용)
```bash
#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rake assets:clean RAILS_ENV=production
bundle exec rake db:create RAILS_ENV=production || true
bundle exec rake db:migrate RAILS_ENV=production

# 초기 데이터 생성 (선택사항)
# bundle exec rake db:seed RAILS_ENV=production
```

### 8.2 CLAUDE.md 파일 템플릿
```markdown
# CLAUDE.md

이 파일은 Claude Code가 프로젝트를 이해하는 데 도움을 줍니다.

## 프로젝트 개요
- 실시간 채팅 애플리케이션
- Rails 8.0 + Turbo + Stimulus + Action Cable

## 주요 명령어
\`\`\`bash
# 개발 서버 시작
bin/dev

# 테스트 실행
rails test

# 콘솔 실행
rails console

# 마이그레이션
rails db:migrate
\`\`\`

## 아키텍처
- Turbo: 비동기 폼 처리
- Action Cable: WebSocket 실시간 통신
- Stimulus: JavaScript 컨트롤러

## 주의사항
- Action Cable routes 마운트 확인
- WebSocket allowed origins 설정
- 세션 쿠키 이름 확인
```

## 9. 환경 변수 설정

### 9.1 개발 환경 (.env.development)
```bash
# 데이터베이스
DATABASE_URL=sqlite3:db/development.sqlite3

# Action Cable
ACTION_CABLE_URL=ws://localhost:3000/cable

# 기타
RAILS_LOG_TO_STDOUT=true
```

### 9.2 프로덕션 환경 (Render 등)
```bash
# 필수 환경 변수
RAILS_MASTER_KEY=<your-master-key>
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true

# Action Cable
ACTION_CABLE_URL=wss://your-app.onrender.com/cable

# 데이터베이스 (PostgreSQL 사용 시)
# DATABASE_URL=postgresql://user:pass@host/dbname
```

## 10. 초기 데이터 설정

### 10.1 db/seeds.rb
```ruby
# 개발용 초기 데이터
if Rails.env.development?
  # 사용자 생성
  users = []
  5.times do |i|
    users << User.create!(
      name: "User #{i + 1}",
      email: "user#{i + 1}@example.com"
    )
  end
  
  # 채팅방 생성
  chat_rooms = []
  ["General", "Random", "Tech Talk", "Help"].each do |name|
    chat_rooms << ChatRoom.create!(name: name)
  end
  
  # 샘플 메시지
  chat_rooms.each do |room|
    5.times do
      Message.create!(
        content: Faker::Lorem.sentence,
        user: users.sample,
        chat_room: room
      )
    end
  end
  
  puts "Seeded #{User.count} users, #{ChatRoom.count} rooms, #{Message.count} messages"
end
```

## 빠른 시작 명령어 모음

```bash
# 1. 프로젝트 생성 및 설정
rails new my_chat_app && cd my_chat_app

# 2. 필요한 gem 추가 후
bundle install

# 3. 모델 생성
rails g model User name:string email:string:uniq
rails g model ChatRoom name:string
rails g model Message content:text user:references chat_room:references

# 4. 데이터베이스 설정
rails db:create db:migrate

# 5. 컨트롤러 생성
rails g controller ChatRooms index show
rails g controller Messages create
rails g controller Sessions new create destroy

# 6. Stimulus 컨트롤러 생성
rails g stimulus chat_room

# 7. 채널 생성
rails g channel ChatRoom

# 8. 서버 시작
bin/dev
```

이 구조와 설정을 따르면 채팅 기능을 가진 Rails 애플리케이션을 빠르고 안정적으로 시작할 수 있습니다.