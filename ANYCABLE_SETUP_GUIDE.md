# AnyCable 설정 가이드

## AnyCable이란?
AnyCable은 Action Cable의 드롭인 대체제로, WebSocket 서버를 Go, Rust 등 더 효율적인 언어로 실행하면서 Rails 애플리케이션과 연동합니다.

## 장점
- **10배 이상 빠른 성능**
- **메모리 사용량 대폭 감소** (Ruby 대비 5-10배 적음)
- **더 많은 동시 연결 처리** (단일 서버에서 수만 개 연결)
- **수평 확장 용이**

## 설치 방법

### 1. Gemfile 수정
```ruby
# Action Cable 대신 AnyCable 사용
gem "anycable-rails", "~> 1.4"

group :development do
  gem "anycable-rails-jwt"
end
```

### 2. AnyCable 서버 설치
```bash
# macOS
brew install anycable-go

# 또는 Docker 사용
docker pull anycable/anycable-go:latest
```

### 3. 설정 파일 생성
```bash
rails g anycable:setup
```

### 4. config/anycable.yml
```yaml
default: &default
  # AnyCable 서버 URL
  rpc_host: "localhost:50051"
  
  # JWT 인증 사용 (보안 강화)
  jwt_id_key: "user_id"
  jwt_id_param: "user_id"

development:
  <<: *default

production:
  <<: *default
  rpc_host: <%= ENV.fetch("ANYCABLE_RPC_HOST", "localhost:50051") %>
  
  # Redis 설정 (프로덕션)
  redis_url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
  
  # JWT 시크릿
  jwt_secret: <%= ENV["ANYCABLE_JWT_SECRET"] %>
```

### 5. ApplicationCable 수정
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
      # AnyCable은 JWT 토큰으로 인증
      if anycable_jwt_present?
        User.find(request.params[:user_id])
      else
        # 기존 세션 기반 인증 폴백
        session_user_id = request.session[:user_id]
        User.find_by(id: session_user_id) || reject_unauthorized_connection
      end
    end

    def anycable_jwt_present?
      request.params[:token].present?
    end
  end
end
```

### 6. JavaScript 클라이언트 수정
```javascript
// app/javascript/channels/consumer.js
import { createConsumer } from "@rails/actioncable"
import { createCable } from "@anycable/web"

// AnyCable 사용 여부 감지
const isAnyCable = window.ANYCABLE_URL !== undefined

let consumer
if (isAnyCable) {
  // AnyCable 클라이언트
  consumer = createCable(window.ANYCABLE_URL, {
    protocol: 'actioncable-v1-json',
    // JWT 토큰 추가
    queryParams: {
      token: window.ANYCABLE_JWT_TOKEN
    }
  })
} else {
  // 기존 Action Cable
  consumer = createConsumer()
}

export default consumer
```

### 7. 실행 방법

개발 환경:
```bash
# 터미널 1: Rails 서버
rails server

# 터미널 2: AnyCable RPC 서버
bundle exec anycable

# 터미널 3: AnyCable WebSocket 서버
anycable-go --host=localhost --port=8080
```

프로덕션 환경 (Docker Compose):
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    command: bundle exec rails server
    environment:
      - ANYCABLE_RPC_HOST=anycable-rpc:50051
    
  anycable-rpc:
    build: .
    command: bundle exec anycable
    environment:
      - REDIS_URL=redis://redis:6379/1
    
  anycable-go:
    image: anycable/anycable-go:latest
    ports:
      - "8080:8080"
    environment:
      - ANYCABLE_HOST=0.0.0.0
      - ANYCABLE_PORT=8080
      - ANYCABLE_RPC_HOST=anycable-rpc:50051
      - ANYCABLE_REDIS_URL=redis://redis:6379/1
    depends_on:
      - anycable-rpc
      - redis
    
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
```

## 마이그레이션 체크리스트

- [ ] AnyCable gem 설치
- [ ] AnyCable 서버 설치 (Go 버전)
- [ ] 설정 파일 생성 및 구성
- [ ] Connection 클래스 JWT 지원 추가
- [ ] JavaScript 클라이언트 수정
- [ ] Redis 설정 (프로덕션)
- [ ] 로드 밸런서 설정 (필요시)
- [ ] 모니터링 설정

## 성능 비교

| 메트릭 | Action Cable | AnyCable |
|--------|--------------|----------|
| 동시 연결 (단일 서버) | 1,000-2,000 | 10,000-50,000 |
| 메모리 사용량 (1000 연결) | 1-2GB | 100-200MB |
| CPU 사용률 | 높음 | 낮음 |
| 메시지 레이턴시 | 10-50ms | 1-5ms |

## 주의사항

1. **개발 복잡도 증가**: 별도 서버 관리 필요
2. **디버깅 어려움**: Ruby와 Go 양쪽 디버깅 필요
3. **호환성**: 일부 Action Cable 기능 제한

## 결론

- **소규모 앱** (< 1000 동시 사용자): Action Cable로 충분
- **대규모 앱** (> 1000 동시 사용자): AnyCable 권장
- **실시간 성능 중요**: AnyCable 권장