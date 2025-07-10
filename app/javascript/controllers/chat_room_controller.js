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
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
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
        },

        disconnected: () => {
          console.log('Disconnected from ChatRoomChannel')
        },

        received: (data) => {
          this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
          this.scrollToBottom()
        },
        
        speak: (message) => {
          this.perform('speak', { message: message })
        }
      }
    )
  }

  sendMessage(event) {
    event.preventDefault()
    const message = this.messageInputTarget.value.trim()
    
    if (message.length > 0 && this.subscription) {
      this.subscription.perform('speak', { message: message })
      this.messageInputTarget.value = ''
    }
  }

  scrollToBottom() {
    if (this.messagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}