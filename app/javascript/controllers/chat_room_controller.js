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
          console.log('Received broadcast:', data)
          this.messagesTarget.insertAdjacentHTML('beforeend', data.message)
          this.scrollToBottom()
        }
      }
    )
  }

  // Removed sendMessage method - form submits normally via Turbo

  scrollToBottom() {
    if (this.messagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}