class KnowledgeExtractionJob < ApplicationJob
  queue_as :knowledge_extraction
  
  def perform(message_id)
    message = LuigiMessage.find(message_id)
    
    Rails.logger.info "Starting knowledge extraction for message #{message_id}"
    
    result = KnowledgeExtractionService.new(message).call
    
    case result
    in Success(assistant_message)
      Rails.logger.info "Knowledge extraction completed for message #{message_id}"
      
      # Broadcast to WebSocket
      broadcast_extraction_complete(message, assistant_message)
      
    in Failure(error)
      Rails.logger.error "Knowledge extraction failed for message #{message_id}: #{error}"
      
      # Create error message
      error_message = create_error_message(message, error)
      
      # Broadcast error
      broadcast_extraction_error(message, error_message)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Message #{message_id} not found: #{e.message}"
  rescue => e
    Rails.logger.error "Unexpected error in knowledge extraction for message #{message_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e # Re-raise for retry mechanism
  end
  
  private
  
  def broadcast_extraction_complete(original_message, assistant_message)
    session = original_message.luigi_session
    
    ActionCable.server.broadcast(
      "luigi_session_#{session.id}",
      {
        type: 'extraction_complete',
        assistant_message: render_message(assistant_message),
        session_stats: calculate_updated_stats(session),
        entities_count: assistant_message.entities_extracted,
        confidence: assistant_message.confidence_percentage
      }
    )
  end
  
  def broadcast_extraction_error(original_message, error_message)
    session = original_message.luigi_session
    
    ActionCable.server.broadcast(
      "luigi_session_#{session.id}",
      {
        type: 'extraction_error',
        error_message: render_message(error_message),
        original_message_id: original_message.id
      }
    )
  end
  
  def create_error_message(message, error)
    message.luigi_session.luigi_messages.create!(
      message_type: 'system',
      content: "⚠️ Entschuldigung, da ist etwas schiefgegangen beim Verstehen deiner Nachricht.\n\nProbier es nochmal oder formuliere es anders. Ich bin hier um zu helfen! 🤝"
    )
  end
  
  def render_message(message)
    ApplicationController.render(
      partial: 'messages/message',
      locals: { message: message }
    )
  end
  
  def calculate_updated_stats(session)
    session.reload.update_statistics!
    {
      entities_extracted: session.entities_extracted,
      relationships_created: session.relationships_created,
      total_messages: session.total_messages,
      avg_confidence: session.avg_confidence.to_f.round(2),
      knowledge_density: session.knowledge_density.round(3)
    }
  end
end