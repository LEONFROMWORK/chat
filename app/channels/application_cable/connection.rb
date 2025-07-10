module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      Rails.logger.debug "Attempting to find user for Action Cable connection"
      
      # Try to get session from encrypted cookie
      if cookies.encrypted[:_ttt_session].present?
        session_data = cookies.encrypted[:_ttt_session]
        session_user_id = session_data["user_id"] if session_data.is_a?(Hash)
        
        if session_user_id
          Rails.logger.debug "Found user_id in session: #{session_user_id}"
          verified_user = User.find_by(id: session_user_id)
          return verified_user if verified_user
        end
      end
      
      Rails.logger.debug "No valid user found for Action Cable connection"
      reject_unauthorized_connection
    end
  end
end