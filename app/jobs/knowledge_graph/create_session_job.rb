class KnowledgeGraph::CreateSessionJob < ApplicationJob
  queue_as :knowledge_graph
  
  # Retry on Neo4j connection issues
  retry_on Neo4j::Driver::Exceptions::ClientException, wait: :exponentially_longer, attempts: 5
  retry_on Neo4j::Driver::Exceptions::SessionExpiredException, wait: :exponentially_longer, attempts: 3
  retry_on Neo4j::Driver::Exceptions::ServiceUnavailableException, wait: :exponentially_longer, attempts: 5
  
  def perform(session_id, expert_id)
    Rails.logger.info "Creating Neo4j session node for session #{session_id}"
    
    # Find the session
    session = LuigiSession.find(session_id)
    
    # Create or find expert node
    expert = Graph::ExpertNode.find_or_create_by(expert_id: expert_id) do |node|
      expert_record = LuigiExpert.find_by(user_id: expert_id)
      if expert_record
        node.name = expert_record.name
        node.years_experience = expert_record.years_experience
        node.specializations = expert_record.specializations
        node.domain = expert_record.expertise_domain
      else
        # Fallback defaults
        node.name = "Luigi"
        node.years_experience = 30
        node.specializations = ["bathroom_renovation", "kitchen_renovation", "heating_systems", "insulation"]
      end
    end
    
    # Create session node
    session_node = Graph::SessionNode.create!(
      session_id: session_id,
      session_name: session.session_name,
      status: session.status,
      started_at: session.started_at
    )
    
    # Create CONDUCTED relationship
    expert.sessions << session_node
    
    Rails.logger.info "Successfully created Neo4j session node for #{session_id}"
    
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Session #{session_id} not found: #{e.message}"
  rescue => e
    Rails.logger.error "Failed to create Neo4j session node for #{session_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Don't raise - this is not critical for the main flow
  end
end