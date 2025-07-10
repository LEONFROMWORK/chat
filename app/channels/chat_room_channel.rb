class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    @chat_room = ChatRoom.find(params[:chat_room_id])
    # stream_for 대신 stream_from을 사용하여 사용자별 필터링 가능
    stream_from "chat_room_#{@chat_room.id}_for_user_#{current_user.id}"
    
    # 공통 채널도 구독 (다른 사용자의 메시지 수신용)
    stream_for @chat_room
    
    Rails.logger.info "User #{current_user.id} subscribed to chat room #{@chat_room.id}"
    
    # 구독 성공 메시지 전송
    transmit({ type: 'welcome', message: 'Successfully connected to chat room', user_id: current_user.id })
  end

  def unsubscribed
    Rails.logger.info "User unsubscribed from chat room"
  end
  
  # 클라이언트에서 호출할 수 있는 ping 메서드
  def ping
    Rails.logger.debug "Ping received from user #{current_user.id}"
    # pong 응답 전송
    transmit({ type: 'pong', timestamp: Time.now.to_i })
  end
end