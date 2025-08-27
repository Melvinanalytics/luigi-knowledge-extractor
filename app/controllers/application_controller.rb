class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  before_action :ensure_luigi_exists
  
  private
  
  def ensure_luigi_exists
    @luigi = LuigiExpert.luigi
  end
  
  def current_session
    @current_session ||= LuigiSession.find(session[:current_session_id]) if session[:current_session_id]
  end
  helper_method :current_session
  
  def redirect_to_current_or_new_session
    if current_session&.active?
      redirect_to current_session
    else
      redirect_to new_session_path
    end
  end
  
  protected
  
  def handle_service_result(result, success_action, failure_action = nil)
    case result
    in Success(value)
      success_action.call(value)
    in Failure(error)
      Rails.logger.error "Service failed: #{error}"
      if failure_action
        failure_action.call(error)
      else
        render json: { error: error }, status: :unprocessable_entity
      end
    end
  end
end