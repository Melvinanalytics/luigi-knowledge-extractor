class Graph::SessionNode
  include ActiveGraph::Node
  
  property :session_id, type: String, constraint: :unique
  property :session_name, type: String
  property :status, type: String, default: 'active'
  property :total_messages, type: Integer, default: 0
  property :entities_extracted, type: Integer, default: 0
  property :relationships_created, type: Integer, default: 0
  property :avg_confidence, type: Float, default: 0.0
  property :started_at, type: DateTime, default: -> { DateTime.current }
  property :ended_at, type: DateTime
  property :created_at, type: DateTime, default: -> { DateTime.current }
  
  has_one :in, :expert, type: :CONDUCTED, model_class: 'Graph::ExpertNode'
  has_many :out, :discussed_entities, type: :DISCUSSED, model_class: 'Graph::KnowledgeEntity'
  has_many :out, :generated_relationships, type: :GENERATED, model_class: 'Graph::KnowledgeRelationship'
  
  validates :session_id, presence: true
  
  def duration_seconds
    end_time = ended_at || DateTime.current
    (end_time - started_at).to_i
  end
  
  def knowledge_density
    return 0.0 if total_messages.zero?
    (entities_extracted + relationships_created).to_f / total_messages
  end
end