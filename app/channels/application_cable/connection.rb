module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :session_id
    
    def connect
      self.session_id = request.session.id || SecureRandom.hex(8)
      Rails.logger.info "ActionCable connection established for session: #{session_id}"
    end
    
    private
    
    def find_verified_user
      # For now, we'll use session-based identification
      # In a real app with authentication, you'd verify the user here
      session_id
    end
  end
end