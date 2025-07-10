import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import { WebSocketReconnector } from "./websocket_reconnect_controller"

export default class extends Controller {
  static targets = ["messages", "messageInput", "connectionStatus"]
  static values = { chatRoomId: Number }

  // Ping 설정
  PING_INTERVAL = 50000 // 50초마다 ping (60초 타임아웃보다 짧게)
  PONG_TIMEOUT = 5000   // 5초 내에 pong 응답이 없으면 재연결

  connect() {
    console.log("ChatRoom controller connected", this.chatRoomIdValue)
    
    // 재연결 관리자 초기화
    this.reconnector = new WebSocketReconnector(consumer)
    
    // 구독 생성
    this.subscription = this.createSubscription()
    
    // 초기 UI 설정
    this.scrollToBottom()
    this.updateConnectionStatus('connecting')
    
    // Ping 시작
    this.startPingInterval()
    
    // 페이지 가시성 변경 감지
    this.setupVisibilityHandler()
  }

  disconnect() {
    this.stopPingInterval()
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.visibilityHandler) {
      document.removeEventListener('visibilitychange', this.visibilityHandler)
    }
  }

  createSubscription() {
    return consumer.subscriptions.create(
      { 
        channel: "ChatRoomChannel",
        chat_room_id: this.chatRoomIdValue
      },
      {
        connected: () => {
          console.log('Connected to ChatRoomChannel')
          this.handleConnected()
        },

        disconnected: () => {
          console.log('Disconnected from ChatRoomChannel')
          this.handleDisconnected()
        },

        received: (data) => {
          this.handleReceivedData(data)
        }
      }
    )
  }

  handleConnected() {
    this.updateConnectionStatus('connected')
    this.reconnector.resetReconnectInterval()
    this.startPingInterval()
  }

  handleDisconnected() {
    this.updateConnectionStatus('disconnected')
    this.stopPingInterval()
    this.reconnector.handleConnectionLoss()
  }

  handleReceivedData(data) {
    console.log('Received:', data)
    
    switch(data.type) {
      case 'welcome':
        console.log('Welcome message received')
        break
      case 'pong':
        this.handlePong(data)
        break
      case 'message':
        // 기존 메시지 처리 로직
        this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
        this.scrollToBottom()
        break
      default:
        // Action Cable broadcast로 온 메시지
        if (data.message) {
          this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
          this.scrollToBottom()
        }
    }
  }

  // Ping-Pong 메커니즘
  startPingInterval() {
    this.stopPingInterval() // 기존 인터벌 정리
    
    this.pingInterval = setInterval(() => {
      if (this.subscription && consumer.connection.isOpen()) {
        console.log('Sending ping...')
        this.lastPingTime = Date.now()
        this.subscription.perform('ping')
        
        // Pong 타임아웃 설정
        this.pongTimeout = setTimeout(() => {
          console.error('Pong timeout - connection may be stale')
          this.handleDisconnected()
        }, this.PONG_TIMEOUT)
      }
    }, this.PING_INTERVAL)
  }

  stopPingInterval() {
    if (this.pingInterval) {
      clearInterval(this.pingInterval)
      this.pingInterval = null
    }
    if (this.pongTimeout) {
      clearTimeout(this.pongTimeout)
      this.pongTimeout = null
    }
  }

  handlePong(data) {
    if (this.pongTimeout) {
      clearTimeout(this.pongTimeout)
      this.pongTimeout = null
    }
    
    const latency = Date.now() - this.lastPingTime
    console.log(`Pong received (latency: ${latency}ms)`)
    this.updateConnectionStatus('connected', latency)
  }

  // 페이지 가시성 처리
  setupVisibilityHandler() {
    this.visibilityHandler = () => {
      if (document.visibilityState === 'visible') {
        console.log('Page became visible, checking connection...')
        
        // 연결 상태 확인 후 필요시 재연결
        setTimeout(() => {
          if (!consumer.connection.isOpen()) {
            console.log('Connection lost while page was hidden, reconnecting...')
            consumer.connection.open()
          } else {
            // 연결은 있지만 오래된 경우 ping 전송
            if (this.subscription) {
              this.subscription.perform('ping')
            }
          }
        }, 500)
      }
    }
    
    document.addEventListener('visibilitychange', this.visibilityHandler)
  }

  // UI 업데이트
  updateConnectionStatus(status, latency = null) {
    if (this.hasConnectionStatusTarget) {
      const statusText = {
        'connecting': '연결 중...',
        'connected': `연결됨${latency ? ` (${latency}ms)` : ''}`,
        'disconnected': '연결 끊김'
      }
      
      this.connectionStatusTarget.textContent = statusText[status] || status
      this.connectionStatusTarget.className = `connection-status status-${status}`
    }
  }

  scrollToBottom() {
    if (this.messagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}