class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    @chat_room = ChatRoom.find(params[:chat_room_id])
    stream_for @chat_room
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
  
  def speak(data)
    message = @chat_room.messages.create!(
      content: data['message'],
      user: current_user
    )
    
    ChatRoomChannel.broadcast_to(@chat_room, {
      message: render_message(message)
    })
  end
  
  private
  
  def render_message(message)
    ApplicationController.renderer.render(
      partial: 'messages/message',
      locals: { message: message }
    )
  end
end