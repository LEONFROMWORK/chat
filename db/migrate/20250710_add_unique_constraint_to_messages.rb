class AddUniqueConstraintToMessages < ActiveRecord::Migration[8.0]
  def change
    # 메시지 중복 방지를 위한 인덱스 추가
    # 같은 사용자가 같은 채팅방에 같은 내용을 1초 이내에 보내는 것을 방지
    add_index :messages, [:user_id, :chat_room_id, :content, :created_at], 
              unique: true, 
              name: 'index_messages_on_duplicate_prevention'
  end
end