class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    @chat_room = ChatRoom.find(params[:chat_room_id])
    stream_for @chat_room
    Rails.logger.info "User #{current_user.id} subscribed to chat room #{@chat_room.id}"
  end

  def unsubscribed
    Rails.logger.info "User unsubscribed from chat room"
  end
end