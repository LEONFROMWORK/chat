module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if session_user_id = request.session[:user_id]
        verified_user = User.find_by(id: session_user_id)
        verified_user || reject_unauthorized_connection
      else
        reject_unauthorized_connection
      end
    end
  end
end