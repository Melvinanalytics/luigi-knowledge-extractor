class KnowledgeGraph::UpdateGraphJob < ApplicationJob
  queue_as :knowledge_graph
  
  # Retry on Neo4j connection issues
  retry_on Neo4j::Driver::Exceptions::ClientException, wait: :exponentially_longer, attempts: 5
  retry_on Neo4j::Driver::Exceptions::SessionExpiredException, wait: :exponentially_longer, attempts: 3
  retry_on Neo4j::Driver::Exceptions::ServiceUnavailableException, wait: :exponentially_longer, attempts: 5
  
  def perform(session_id, message_id, extraction_data)
    Rails.logger.info "Updating Neo4j graph for session #{session_id}, message #{message_id}"
    
    session = LuigiSession.find(session_id)
    message = LuigiMessage.find(message_id)
    
    entities_data = extraction_data["entities"] || []
    relationships_data = extraction_data["relationships"] || []
    
    # Process in Neo4j transaction
    ActiveGraph::Base.transaction do
      # Find or create session node
      session_node = Graph::SessionNode.find_or_create_by(session_id: session_id.to_s) do |node|
        node.session_name = session.session_name
        node.status = session.status
        node.started_at = session.started_at
      end
      
      # Create or update entities
      entity_nodes = create_or_update_entities(entities_data, session_node)
      
      # Create relationships between entities
      create_relationships(relationships_data, entity_nodes, session_node)
      
      # Update session node statistics
      update_session_node_stats(session_node, session)
      
      Rails.logger.info "Successfully updated Neo4j graph for session #{session_id}"
    end
    
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Record not found for session #{session_id}: #{e.message}"
  rescue => e
    Rails.logger.error "Failed to update Neo4j graph for session #{session_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Don't raise - graph updates are not critical for main flow
  end
  
  private
  
  def create_or_update_entities(entities_data, session_node)
    entity_nodes = {}
    
    entities_data.each do |entity_data|
      next unless entity_data.is_a?(Hash)
      
      value = entity_data["value"]
      entity_type = entity_data["type"]
      confidence = entity_data["confidence"].to_f
      context = entity_data["context"]
      
      # Skip invalid entities
      next if value.blank? || entity_type.blank?
      
      begin
        # Create or update entity
        entity = Graph::KnowledgeEntity.find_or_create_with_mention(
          value, entity_type, confidence, context
        )
        
        if entity
          # Connect to session
          session_node.discussed_entities << entity unless session_node.discussed_entities.include?(entity)
          entity_nodes[value] = entity
        else
          Rails.logger.warn "Failed to create/find entity: #{value} (#{entity_type})"
        end
      rescue => e
        Rails.logger.error "Error processing entity #{value}: #{e.message}"
        next
      end
    end
    
    Rails.logger.info "Successfully processed #{entity_nodes.size} out of #{entities_data.size} entities"
    entity_nodes
  end
  
  def create_relationships(relationships_data, entity_nodes, session_node)
    relationships_data.each do |rel_data|
      from_value = rel_data["from"]
      to_value = rel_data["to"]
      relation_type = rel_data["relation"]
      confidence = rel_data["confidence"].to_f
      context = rel_data["context"]
      
      from_entity = entity_nodes[from_value]
      to_entity = entity_nodes[to_value]
      
      if from_entity && to_entity
        # Create or update relationship
        Graph::KnowledgeRelationship.create_or_update_relationship(
          from_entity, to_entity, relation_type, confidence, context
        )
      else
        Rails.logger.warn "Could not create relationship: missing entities #{from_value} -> #{to_value}"
      end
    end
  end
  
  def update_session_node_stats(session_node, session)
    session_node.update(
      total_messages: session.total_messages,
      entities_extracted: session.entities_extracted,
      relationships_created: session.relationships_created,
      avg_confidence: session.avg_confidence.to_f,
      status: session.status
    )
  end
end