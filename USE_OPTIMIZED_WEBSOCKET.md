# WebSocket 최적화 사용 가이드

## 선택 방법

### 1. 기존 방식 사용 (간단한 구현)
```erb
<div data-controller="chat-room" data-chat-room-chat-room-id-value="<%= @chat_room.id %>">
```

### 2. 최적화된 방식 사용 (권장)
```erb
<div data-controller="chat-room-optimized" data-chat-room-optimized-chat-room-id-value="<%= @chat_room.id %>">
```

## 최적화된 방식의 장점

1. **Ping-Pong 메커니즘**: 50초마다 ping을 보내고 pong 응답 확인
2. **지수 백오프 재연결**: 네트워크 문제 시 점진적 재연결
3. **연결 상태 표시**: 사용자가 연결 상태를 실시간으로 확인 가능
4. **페이지 재활성화 처리**: 탭 전환 후 자동 재연결
5. **레이턴시 모니터링**: 연결 품질 확인 가능

## 테스트 방법

1. 브라우저 개발자 도구 콘솔 열기
2. 다음 로그 확인:
   - "Sending ping..."
   - "Pong received (latency: XXms)"
   - 연결 상태 변경 시 UI 업데이트

3. 연결 끊김 테스트:
   - 네트워크 끊기
   - 재연결 시도 로그 확인
   - 자동 재연결 확인

## 프로덕션 배포 시

1. Nginx 설정 업데이트 (nginx_websocket_config.conf 참조)
2. Action Cable 설정에서 staleThreshold 조정
3. 모니터링 도구로 WebSocket 연결 상태 추적