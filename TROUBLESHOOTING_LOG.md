# Rails 채팅 앱 트러블슈팅 로그

## 프로젝트 개요
- **목표**: Ruby on Rails와 Tailwind CSS를 사용한 실시간 채팅 웹앱
- **주요 기능**: 다중 채팅방, 실시간 메시징, 사용자 인증
- **배포 플랫폼**: Render (유료 플랜)

## 문제 해결 타임라인

### 1단계: 초기 개발 (성공)
- Rails 8.0.2 애플리케이션 생성
- User, ChatRoom, Message 모델 생성
- 기본 채팅 UI 구현 (Tailwind CSS CDN 사용)
- 간단한 이메일 기반 인증 구현

### 2단계: Render 배포 시도 (실패 → 성공)

#### 문제 1: PostgreSQL 연결 실패
**증상**: 
```
PG::ConnectionBad: connection to server at "dpg-xxx.oregon-postgres.render.com"
```

**원인**: Render 무료 플랜의 PostgreSQL 제한

**해결**:
1. SQLite3로 데이터베이스 변경
2. Gemfile 수정: `gem 'sqlite3', '>= 2.4'`
3. database.yml 수정

#### 문제 2: Credentials 오류
**증상**:
```
ActiveSupport::MessageEncryptor::InvalidMessage
```

**원인**: master.key와 credentials.yml.enc 불일치

**해결**:
1. 기존 credentials 파일 삭제
2. 새로운 credentials 생성
3. Render에 올바른 RAILS_MASTER_KEY 설정

#### 문제 3: Solid Gem 의존성 오류
**증상**: 
```
Could not find solid_cable-0.1.0, solid_cache-0.1.0, solid_queue-0.1.0
```

**원인**: Rails 8의 기본 gem들이 프로덕션에서 문제 발생

**해결**:
1. Gemfile에서 solid 관련 gem 제거
2. production.rb에서 관련 설정 변경
3. cable.yml을 async adapter로 변경

#### 문제 4: Asset 파일 404 오류
**증상**: CSS/JS 파일들이 로드되지 않음

**해결**:
1. `config.public_file_server.enabled = true` 설정
2. render-build.sh에 assets:precompile 추가

### 3단계: 실시간 채팅 구현 (실패 → 성공)

#### 문제 5: 메시지 전송 시 페이지 리로드
**증상**: Send 버튼 클릭 시 전체 페이지가 새로고침됨

**원인**: 일반 폼 제출로 처리됨

**해결**:
1. `form_with`에 `local: false` 옵션 추가
2. Turbo Stream 응답 구현
3. create.turbo_stream.erb 템플릿 생성

#### 문제 6: 실시간 메시지 수신 불가
**증상**: 다른 사용자의 메시지가 실시간으로 표시되지 않음

**원인**: Action Cable 설정 및 연결 문제

**해결 과정**:

1. **Action Cable 마운트 누락**
   ```ruby
   # config/routes.rb
   mount ActionCable.server => '/cable'
   ```

2. **WebSocket 인증 문제**
   ```ruby
   # app/channels/application_cable/connection.rb
   def find_verified_user
     if cookies.encrypted[:_ttt_session].present?
       session_data = cookies.encrypted[:_ttt_session]
       session_user_id = session_data["user_id"] if session_data.is_a?(Hash)
       # ...
     end
   end
   ```

3. **JavaScript 모듈 로딩 문제**
   - 초기: 인라인 script 태그 사용 (실패)
   - 해결: Stimulus Controller 사용

4. **Action Cable 설정 추가**
   ```ruby
   # config/environments/development.rb
   config.action_cable.allowed_request_origins = ['http://localhost:3001']
   
   # config/environments/production.rb
   config.action_cable.url = 'wss://chat-29bz.onrender.com/cable'
   config.action_cable.allowed_request_origins = ['https://chat-29bz.onrender.com']
   ```

5. **메시지 전송 흐름 재설계**
   - 제거: ChatRoomChannel의 speak 메서드
   - 제거: JavaScript에서 폼 제출 인터셉트
   - 구현: MessagesController → Action Cable 브로드캐스트

## 최종 아키텍처

### 메시지 전송 흐름
1. 사용자가 메시지 입력 후 Send 클릭
2. Turbo가 폼을 비동기로 제출 (AJAX)
3. MessagesController#create 실행
4. 메시지 저장 후 두 가지 응답:
   - 송신자: Turbo Stream으로 즉시 업데이트
   - 다른 사용자: Action Cable로 브로드캐스트

### 핵심 컴포넌트
- **Turbo**: 비동기 폼 제출 및 DOM 업데이트
- **Action Cable**: WebSocket 기반 실시간 통신
- **Stimulus**: JavaScript 동작 관리

## 교훈 및 권장사항

### Do's (해야 할 것들)
1. ✅ Action Cable routes 마운트 확인
2. ✅ WebSocket allowed origins 설정
3. ✅ 세션 쿠키 이름 확인 (_app_session)
4. ✅ Stimulus Controller 사용으로 JavaScript 관리
5. ✅ 브라우저 콘솔로 WebSocket 연결 디버깅
6. ✅ 두 개의 브라우저로 실시간 기능 테스트

### Don'ts (하지 말아야 할 것들)
1. ❌ Action Cable에서 직접 데이터베이스 조작
2. ❌ 복잡한 JavaScript 인라인 코드
3. ❌ WebSocket과 HTTP 요청 혼용
4. ❌ 프로덕션에서 개발용 gem 사용
5. ❌ credentials 파일 불일치 상태로 배포

## 디버깅 명령어 모음

```bash
# Rails 서버 로그 확인
tail -f log/development.log | grep -E "ActionCable|ChatRoom"

# Action Cable 연결 테스트
curl -H "Connection: Upgrade" -H "Upgrade: websocket" http://localhost:3001/cable

# 프로세스 확인
ps aux | grep -E "rails|puma"

# Render 빌드 로그
render logs --service-id <SERVICE_ID>
```

## 성능 최적화 팁

1. **메시지 로딩 최적화**
   - 최근 50개 메시지만 로드
   - 무한 스크롤 구현 고려

2. **WebSocket 연결 관리**
   - 페이지 이탈 시 구독 해제
   - 재연결 로직 구현

3. **캐싱 전략**
   - 자주 접근하는 채팅방 정보 캐싱
   - 사용자 정보 캐싱

---
작성일: 2025-07-10
총 디버깅 시간: 약 3시간
최종 상태: ✅ 모든 기능 정상 작동