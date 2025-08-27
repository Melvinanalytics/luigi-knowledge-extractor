class KnowledgeExportService
  include Dry::Monads[:result]
  
  def initialize(session)
    @session = session
  end
  
  def call
    Success({
      session_metadata: session_metadata,
      messages: messages_data,
      entities: entities_data,
      relationships: relationships_data,
      knowledge_graph: knowledge_graph_export,
      statistics: session_statistics,
      export_metadata: export_metadata
    })
  rescue => error
    Rails.logger.error "Export failed: #{error.message}"
    Failure("Export failed: #{error.message}")
  end
  
  private
  
  def session_metadata
    {
      id: @session.id,
      expert_name: @session.luigi_expert.name,
      expert_id: @session.luigi_expert.user_id,
      session_name: @session.session_name,
      description: @session.description,
      status: @session.status,
      duration_seconds: @session.duration_seconds,
      started_at: @session.started_at.iso8601,
      ended_at: @session.ended_at&.iso8601,
      total_messages: @session.total_messages,
      entities_extracted: @session.entities_extracted,
      relationships_created: @session.relationships_created,
      avg_confidence: @session.avg_confidence.to_f.round(2)
    }
  end
  
  def messages_data
    @session.luigi_messages.includes(:luigi_entities, :luigi_relationships)
            .chronological.map do |message|
      {
        id: message.id,
        message_type: message.message_type,
        content: message.content,
        confidence_score: message.confidence_score.to_f.round(2),
        entities_extracted: message.entities_extracted,
        processing_time_ms: message.processing_time_ms,
        created_at: message.created_at.iso8601,
        metadata: message.metadata,
        entities: message.luigi_entities.map do |entity|
          {
            type: entity.entity_type,
            value: entity.entity_value,
            confidence: entity.confidence.to_f.round(2),
            context: entity.context
          }
        end,
        relationships: message.luigi_relationships.map do |rel|
          {
            from: rel.from_entity,
            relation: rel.relation_type,
            to: rel.to_entity,
            confidence: rel.confidence.to_f.round(2),
            context: rel.context
          }
        end
      }
    end
  end
  
  def entities_data
    entity_summary = @session.luigi_entities.group(:entity_type).count
    entity_values = @session.luigi_entities.group(:entity_value)
                           .select('entity_value, COUNT(*) as mention_count, AVG(confidence) as avg_confidence')
                           .order('mention_count DESC')
    
    {
      by_type: entity_summary,
      most_mentioned: entity_values.limit(20).map do |entity|
        {
          value: entity.entity_value,
          mention_count: entity.mention_count,
          avg_confidence: entity.avg_confidence.to_f.round(2)
        }
      end,
      all_entities: @session.luigi_entities.map do |entity|
        {
          type: entity.entity_type,
          value: entity.entity_value,
          confidence: entity.confidence.to_f.round(2),
          context: entity.context,
          created_at: entity.created_at.iso8601
        }
      end
    }
  end
  
  def relationships_data
    relationship_summary = @session.luigi_relationships.group(:relation_type).count
    strongest_rels = @session.luigi_relationships
                            .select('from_entity, relation_type, to_entity, AVG(confidence) as avg_confidence, COUNT(*) as mention_count')
                            .group(:from_entity, :relation_type, :to_entity)
                            .order('avg_confidence DESC, mention_count DESC')
                            .limit(20)
    
    {
      by_type: relationship_summary,
      strongest: strongest_rels.map do |rel|
        {
          from: rel.from_entity,
          relation: rel.relation_type,
          to: rel.to_entity,
          avg_confidence: rel.avg_confidence.to_f.round(2),
          mention_count: rel.mention_count
        }
      end,
      all_relationships: @session.luigi_relationships.map do |rel|
        {
          from: rel.from_entity,
          relation: rel.relation_type,
          to: rel.to_entity,
          confidence: rel.confidence.to_f.round(2),
          context: rel.context,
          created_at: rel.created_at.iso8601
        }
      end
    }
  end
  
  def knowledge_graph_export
    # This would query Neo4j for the complete graph structure
    # For now, return computed statistics
    {
      nodes_count: @session.luigi_entities.count,
      edges_count: @session.luigi_relationships.count,
      entity_types: @session.luigi_entities.distinct.pluck(:entity_type),
      relation_types: @session.luigi_relationships.distinct.pluck(:relation_type),
      knowledge_density: @session.knowledge_density.round(3),
      graph_data: LuigiRelationship.knowledge_graph_data.select do |rel|
        rel[:session_id] == @session.id
      end
    }
  end
  
  def session_statistics
    messages_by_type = @session.luigi_messages.group(:message_type).count
    entities_by_confidence = @session.luigi_entities
                                    .group('CASE WHEN confidence >= 0.8 THEN \'high\' WHEN confidence >= 0.6 THEN \'medium\' ELSE \'low\' END')
                                    .count
    
    {
      messages_by_type: messages_by_type,
      entities_by_confidence: entities_by_confidence,
      avg_processing_time_ms: @session.luigi_messages.average(:processing_time_ms)&.round(2) || 0,
      knowledge_density: @session.knowledge_density.round(3),
      session_duration_formatted: @session.duration_formatted,
      most_confident_entities: @session.luigi_entities.order(confidence: :desc).limit(10)
                                      .pluck(:entity_value, :confidence).map do |value, conf|
        { value: value, confidence: conf.to_f.round(2) }
      end
    }
  end
  
  def export_metadata
    {
      exported_at: Time.current.iso8601,
      exporter: 'luigi_knowledge_extractor_rails',
      version: '1.0.0',
      format_version: '1.0',
      export_type: 'full_session',
      Rails.env => Rails.env,
      total_export_size_bytes: nil # Would be calculated after serialization
    }
  end
end