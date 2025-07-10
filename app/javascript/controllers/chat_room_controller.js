import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["messages", "messageInput"]
  static values = { chatRoomId: Number }

  connect() {
    console.log("ChatRoom controller connected", this.chatRoomIdValue)
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
          this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
          this.scrollToBottom()
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
}