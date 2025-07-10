// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

// 연결 모니터 설정 조정
consumer.connection.monitor.staleThreshold = 60  // 60초 (기본값: 6초)
consumer.connection.monitor.pollInterval = 3      // 3초마다 확인 (기본값: 3초)
consumer.connection.monitor.reconnectAttempts = 10 // 재연결 시도 횟수

// 연결 상태 로깅
consumer.connection.monitor.visibilityDidChange = function() {
  if (document.visibilityState === 'visible') {
    console.log('Page became visible, ensuring connection...')
    setTimeout(() => {
      if (!consumer.connection.isOpen()) {
        consumer.connection.open()
      }
    }, 200)
  }
}

// 페이지가 다시 활성화될 때 연결 확인
document.addEventListener('visibilitychange', () => {
  consumer.connection.monitor.visibilityDidChange()
})

export default consumer
