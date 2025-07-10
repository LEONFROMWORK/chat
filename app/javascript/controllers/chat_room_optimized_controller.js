import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import { WebSocketReconnector } from "./websocket_reconnect_controller"

export default class extends Controller {
  static targets = ["messages", "messageInput", "connectionStatus"]
  static values = { 
    chatRoomId: Number,
    currentUserId: Number
  }

  // Ping 설정
  PING_INTERVAL = 50000 // 50초마다 ping (60초 타임아웃보다 짧게)
  PONG_TIMEOUT = 5000   // 5초 내에 pong 응답이 없으면 재연결

  connect() {
    console.log("ChatRoom controller connected", this.chatRoomIdValue, "User:", this.currentUserIdValue)
    
    // 재연결 관리자 초기화
    this.reconnector = new WebSocketReconnector(consumer)
    
    // 메시지 ID 추적 (중복 방지)
    this.processedMessageIds = new Set()
    
    // 구독 생성
    this.subscription = this.createSubscription()
    
    // 초기 UI 설정
    this.scrollToBottom()
    this.updateConnectionStatus('connecting')
    
    // 기존 메시지 ID 추적 (중복 방지)
    this.trackExistingMessages()
    
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
    
    // 특별한 메시지 타입 처리
    if (data.type) {
      switch(data.type) {
        case 'welcome':
          console.log('Welcome message received')
          break
        case 'pong':
          this.handlePong(data)
          break
        default:
          console.log('Unknown message type:', data.type)
      }
      return
    }
    
    // 일반 채팅 메시지 처리
    if (data.message && data.message_id) {
      // 중복 메시지 방지
      if (this.processedMessageIds.has(data.message_id)) {
        console.log('Duplicate message ignored:', data.message_id)
        return
      }
      
      // 자신이 보낸 메시지는 Action Cable로 받지 않음 (Turbo Stream으로 이미 추가됨)
      if (data.sender_id === this.currentUserIdValue) {
        console.log('Own message ignored from broadcast:', data.message_id)
        return
      }
      
      // 메시지 추가
      console.log('Adding message from other user:', data.message_id)
      this.processedMessageIds.add(data.message_id)
      this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
      this.scrollToBottom()
      
      // 메시지 수신 시 사운드나 알림 (선택사항)
      this.notifyNewMessage()
    }
  }
  
  notifyNewMessage() {
    // 간단한 시각적 피드백
    if (document.visibilityState === 'hidden') {
      // 페이지가 백그라운드일 때 타이틀 변경
      const originalTitle = document.title
      document.title = '💬 새 메시지!'
      setTimeout(() => {
        document.title = originalTitle
      }, 3000)
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
  
  trackExistingMessages() {
    // 페이지 로드 시 이미 표시된 메시지들의 ID를 추적
    const existingMessages = this.messagesTarget.querySelectorAll('[data-message-id]')
    existingMessages.forEach(messageEl => {
      const messageId = parseInt(messageEl.dataset.messageId)
      if (messageId) {
        this.processedMessageIds.add(messageId)
      }
    })
    console.log('Tracking existing messages:', this.processedMessageIds.size)
  }
}