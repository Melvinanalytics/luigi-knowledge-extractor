class Graph::KnowledgeEntity
  include ActiveGraph::Node
  
  property :value, type: String, constraint: :unique
  property :entity_type, type: String, index: :exact
  property :confidence, type: Float
  property :context, type: String
  property :mention_count, type: Integer, default: 1
  property :first_mentioned, type: DateTime, default: -> { DateTime.current }
  property :last_mentioned, type: DateTime, default: -> { DateTime.current }
  property :luigi_knowledge, type: Boolean, default: true
  property :created_at, type: DateTime, default: -> { DateTime.current }
  property :updated_at, type: DateTime, default: -> { DateTime.current }
  
  has_many :out, :relates_to, type: :RELATES_TO, model_class: 'Graph::KnowledgeEntity'
  has_many :in, :related_from, type: :RELATES_TO, model_class: 'Graph::KnowledgeEntity'
  has_many :in, :discussed_in, type: :DISCUSSED, model_class: 'Graph::SessionNode'
  has_many :in, :possessed_by, type: :POSSESSES, model_class: 'Graph::ExpertNode'
  
  validates :value, :entity_type, presence: true
  
  def self.find_or_create_with_mention(value, entity_type, confidence = 0.8, context = nil)
    # Validate required parameters
    return nil if value.blank? || entity_type.blank?
    
    # Normalize confidence to valid range
    confidence = [[confidence.to_f, 0.0].max, 1.0].min
    
    entity = find_by(value: value.to_s.strip)
    
    if entity
      # Update existing entity
      begin
        # Use maximum confidence instead of average to avoid degradation
        new_confidence = [entity.confidence, confidence].max
        
        entity.update(
          mention_count: entity.mention_count + 1,
          last_mentioned: DateTime.current,
          confidence: new_confidence,
          context: context || entity.context
        )
      rescue => e
        Rails.logger.error "Failed to update entity #{value}: #{e.message}"
        return entity  # Return existing entity even if update failed
      end
    else
      # Create new entity
      begin
        entity = create!(
          value: value.to_s.strip,
          entity_type: entity_type.to_s.strip,
          confidence: confidence,
          context: context&.to_s,
          mention_count: 1
        )
      rescue => e
        Rails.logger.error "Failed to create entity #{value} (#{entity_type}): #{e.message}"
        return nil
      end
    end
    
    entity
  end
  
  def related_entities_count
    relates_to.count + related_from.count
  end
  
  def strongest_relationships(limit = 5)
    query = <<~CYPHER
      MATCH (this)-[r:RELATES_TO]-(other:KnowledgeEntity)
      WHERE id(this) = $entity_id
      RETURN other, type(r) as relationship_type, r.confidence as confidence
      ORDER BY r.confidence DESC
      LIMIT $limit
    CYPHER
    
    ActiveGraph::Base.query(query, entity_id: id, limit: limit)
  end
end