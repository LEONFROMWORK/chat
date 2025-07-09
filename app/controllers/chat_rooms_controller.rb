class ChatRoomsController < ApplicationController
  before_action :require_user
  
  def index
    @chat_rooms = ChatRoom.all
    # Create default chat room if none exist
    if @chat_rooms.empty?
      ChatRoom.create(name: "General")
      @chat_rooms = ChatRoom.all
    end
  end

  def show
    @chat_room = ChatRoom.find(params[:id])
    @messages = @chat_room.messages.includes(:user).recent.reverse
    @message = Message.new
  end
end