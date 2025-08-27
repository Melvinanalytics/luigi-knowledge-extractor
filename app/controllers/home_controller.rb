class HomeController < ApplicationController
  def index
    if current_session&.active?
      redirect_to current_session
    else
      @recent_sessions = @luigi.luigi_sessions.recent.limit(5)
      @stats = {
        total_sessions: @luigi.luigi_sessions.count,
        total_messages: @luigi.total_messages_processed,
        avg_confidence: @luigi.avg_session_confidence
      }
    end
  end
end