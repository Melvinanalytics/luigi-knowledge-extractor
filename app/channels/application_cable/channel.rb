module ApplicationCable
  class Channel < ActionCable::Channel::Base
    protected
    
    def log_subscription_activity(action, details = {})
      Rails.logger.info "#{self.class.name} #{action}: #{details.inspect}"
    end
    
    def safe_find_session(session_id)
      LuigiSession.find(session_id)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Session #{session_id} not found"
      reject
      nil
    end
  end
end