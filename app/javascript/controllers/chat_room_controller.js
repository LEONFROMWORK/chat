import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["messages", "messageInput"]
  static values = { 
    chatRoomId: Number,
    currentUserId: Number
  }

  connect() {
    console.log("ChatRoom controller connected", this.chatRoomIdValue, "User:", this.currentUserIdValue)
    
    // 메시지 ID 추적 (중복 방지)
    this.processedMessageIds = new Set()
    this.trackExistingMessages()
    
    this.subscription = this.createSubscription()
    this.scrollToBottom()
    console.log("Subscription created:", this.subscription)
    
    // 연결 상태 모니터링
    this.monitorConnection()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.connectionMonitor) {
      clearInterval(this.connectionMonitor)
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
          this.connectionStatus = 'connected'
        },

        disconnected: () => {
          console.log('Disconnected from ChatRoomChannel')
          this.connectionStatus = 'disconnected'
          // 재연결 시도
          setTimeout(() => {
            console.log('Attempting to reconnect...')
            consumer.connect()
          }, 1000)
        },

        received: (data) => {
          console.log('Received broadcast:', data)
          
          // 중복 방지 로직
          if (data.message_id) {
            // 로컬 또는 전역 처리된 메시지 확인
            if (this.processedMessageIds.has(data.message_id) || 
                (window.processedMessageIds && window.processedMessageIds.has(data.message_id))) {
              console.log('Duplicate message ignored:', data.message_id)
              return
            }
            
            // 자신이 보낸 메시지는 무시 (Turbo Stream으로 이미 추가됨)
            const currentUserId = this.currentUserIdValue || window.currentUserId;
            if (data.sender_id === currentUserId) {
              console.log('Own message ignored from broadcast:', data.message_id)
              this.processedMessageIds.add(data.message_id)
              if (window.processedMessageIds) {
                window.processedMessageIds.add(data.message_id);
              }
              return
            }
            
            this.processedMessageIds.add(data.message_id)
            if (window.processedMessageIds) {
              window.processedMessageIds.add(data.message_id);
            }
          }
          
          // 메시지 추가
          if (data.message) {
            this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
            this.scrollToBottom()
          }
        }
      }
    )
  }
  
  monitorConnection() {
    // 30초마다 연결 상태 확인 및 ping 전송
    this.connectionMonitor = setInterval(() => {
      if (!consumer.connection.isOpen()) {
        console.log('Connection lost, reconnecting...')
        consumer.connect()
      } else if (this.subscription && this.connectionStatus === 'connected') {
        // 연결이 활성 상태일 때 ping 전송
        this.subscription.perform('ping')
        console.log('Ping sent to keep connection alive')
      }
    }, 30000)
  }

  // Removed sendMessage method - form submits normally via Turbo

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