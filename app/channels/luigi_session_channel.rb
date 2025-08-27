class LuigiSessionChannel < ApplicationCable::Channel
  def subscribed
    session_id = params[:session_id]
    
    return reject unless session_id
    
    @session = safe_find_session(session_id)
    return unless @session
    
    stream_from "luigi_session_#{session_id}"
    
    log_subscription_activity("subscribed", { session_id: session_id })
    
    # Send current session stats
    transmit({
      type: 'connection_established',
      session_stats: current_session_stats
    })
  end
  
  def unsubscribed
    log_subscription_activity("unsubscribed", { session_id: params[:session_id] })
  end
  
  def send_message(data)
    return reject unless @session
    
    content = data['content']&.strip
    message_type = data['message_type'] || 'user'
    
    return reject if content.blank?
    
    # Create message
    message = @session.luigi_messages.create!(
      message_type: message_type,
      content: content
    )
    
    # Broadcast message immediately to show in chat
    broadcast_message_sent(message)
    
    # Trigger knowledge extraction if it's a user message
    if message_type == 'user'
      KnowledgeExtractionJob.perform_later(message.id)
      
      # Show processing indicator
      broadcast_processing_started
    end
    
  rescue ActiveRecord::RecordInvalid => e
    transmit({
      type: 'error',
      message: 'Message could not be sent',
      details: e.record.errors.full_messages
    })
  rescue => e
    Rails.logger.error "Failed to send message: #{e.message}"
    transmit({
      type: 'error',
      message: 'An unexpected error occurred'
    })
  end
  
  def typing_start
    return unless @session
    
    ActionCable.server.broadcast(
      "luigi_session_#{@session.id}",
      {
        type: 'typing_start',
        user_id: connection.session_id
      }
    )
  end
  
  def typing_stop
    return unless @session
    
    ActionCable.server.broadcast(
      "luigi_session_#{@session.id}",
      {
        type: 'typing_stop',
        user_id: connection.session_id
      }
    )
  end
  
  private
  
  def broadcast_message_sent(message)
    ActionCable.server.broadcast(
      "luigi_session_#{@session.id}",
      {
        type: 'message_sent',
        message: render_message(message),
        message_id: message.id,
        processing: message.user_message?
      }
    )
  end
  
  def broadcast_processing_started
    ActionCable.server.broadcast(
      "luigi_session_#{@session.id}",
      {
        type: 'processing_started',
        message: 'Luigi denkt nach...'
      }
    )
  end
  
  def render_message(message)
    ApplicationController.render(
      partial: 'messages/message',
      locals: { message: message }
    )
  end
  
  def current_session_stats
    {
      total_messages: @session.total_messages,
      entities_extracted: @session.entities_extracted,
      relationships_created: @session.relationships_created,
      avg_confidence: @session.avg_confidence.to_f.round(2),
      duration_seconds: @session.duration_seconds
    }
  end
end