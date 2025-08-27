class Graph::KnowledgeRelationship
  include ActiveGraph::Relationship
  
  from_class 'Graph::KnowledgeEntity'
  to_class 'Graph::KnowledgeEntity'
  type 'RELATES_TO'
  
  property :relation_type, type: String
  property :confidence, type: Float
  property :context, type: String
  property :mention_count, type: Integer, default: 1
  property :first_mentioned, type: DateTime, default: -> { DateTime.current }
  property :last_mentioned, type: DateTime, default: -> { DateTime.current }
  property :created_at, type: DateTime, default: -> { DateTime.current }
  property :updated_at, type: DateTime, default: -> { DateTime.current }
  
  has_many :in, :generated_by, type: :GENERATED, model_class: 'Graph::SessionNode'
  
  validates :relation_type, :confidence, presence: true
  validates :confidence, numericality: { in: 0.0..1.0 }
  
  def self.create_or_update_relationship(from_entity, to_entity, relation_type, confidence, context = nil)
    # Check if relationship already exists
    existing = from_entity.relates_to.where(
      "endNode.value = $to_value AND type(r) = $rel_type",
      to_value: to_entity.value,
      rel_type: 'RELATES_TO'
    ).first
    
    if existing
      # Update existing relationship
      rel_props = existing.rel
      rel_props.update(
        confidence: [(rel_props.confidence + confidence) / 2, 1.0].min,
        mention_count: rel_props.mention_count + 1,
        last_mentioned: DateTime.current,
        context: context || rel_props.context,
        relation_type: relation_type
      )
      existing
    else
      # Create new relationship
      from_entity.relates_to << to_entity
      rel = from_entity.relates_to.where("endNode.value = $to_value", to_value: to_entity.value).first
      rel.rel.update(
        relation_type: relation_type,
        confidence: confidence,
        context: context,
        mention_count: 1
      )
      rel
    end
  end
  
  def formatted_triple
    "#{from_node.value} → #{relation_type} → #{to_node.value}"
  end
end