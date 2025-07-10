class MessagesController < ApplicationController
  before_action :require_user
  
  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])
    @message = @chat_room.messages.build(message_params)
    @message.user = current_user
    
    if @message.save
      # Broadcast to Action Cable (다른 사용자들에게만)
      ChatRoomChannel.broadcast_to(@chat_room, {
        message: render_to_string(partial: 'messages/message', locals: { message: @message }),
        sender_id: current_user.id,
        message_id: @message.id
      })
      
      # Respond based on request type
      respond_to do |format|
        format.turbo_stream # This will render create.turbo_stream.erb
        format.html { redirect_to chat_room_path(@chat_room) }
      end
    else
      @messages = @chat_room.messages.includes(:user).recent.reverse
      render "chat_rooms/show", status: :unprocessable_entity
    end
  end
  
  private
  
  def message_params
    params.require(:message).permit(:content)
  end
end