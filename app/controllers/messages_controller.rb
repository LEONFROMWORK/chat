class MessagesController < ApplicationController
  before_action :require_user
  
  def create
    # This is now handled by Action Cable
    # Keeping this for fallback
    @chat_room = ChatRoom.find(params[:chat_room_id])
    @message = @chat_room.messages.build(message_params)
    @message.user = current_user
    
    if @message.save
      redirect_to chat_room_path(@chat_room)
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