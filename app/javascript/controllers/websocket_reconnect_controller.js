// WebSocket 재연결을 위한 지수 백오프 전략 구현
export class WebSocketReconnector {
  constructor(consumer) {
    this.consumer = consumer
    this.reconnectInterval = Math.random() * 1000 // 0-1초 랜덤 초기값
    this.maxReconnectInterval = 30000 // 최대 30초
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 10
  }

  scheduleReconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnection attempts reached')
      return
    }

    console.log(`Scheduling reconnect in ${this.reconnectInterval}ms (attempt ${this.reconnectAttempts + 1})`)
    
    setTimeout(() => {
      if (!this.consumer.connection.isOpen()) {
        this.consumer.connection.open()
        this.reconnectAttempts++
        this.reconnectInterval = Math.min(this.reconnectInterval * 2, this.maxReconnectInterval)
      }
    }, this.reconnectInterval)
  }

  resetReconnectInterval() {
    this.reconnectInterval = Math.random() * 1000
    this.reconnectAttempts = 0
    console.log('Connection successful, reset reconnect interval')
  }

  handleConnectionLoss() {
    console.warn('WebSocket connection lost')
    this.scheduleReconnect()
  }
}