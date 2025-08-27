class Graph::ExpertNode
  include ActiveGraph::Node
  
  property :expert_id, type: String, constraint: :unique
  property :name, type: String
  property :domain, type: String, default: 'construction_renovation'
  property :years_experience, type: Integer, default: 30
  property :specializations, type: Array[String], default: []
  property :created_at, type: DateTime, default: -> { DateTime.current }
  property :updated_at, type: DateTime, default: -> { DateTime.current }
  
  has_many :out, :sessions, type: :CONDUCTED, model_class: 'Graph::SessionNode'
  has_many :out, :knowledge, type: :POSSESSES, model_class: 'Graph::KnowledgeEntity'
  
  validates :expert_id, :name, presence: true
  
  def self.find_or_create_luigi
    find_by(expert_id: "luigi-sanierung-expert-001") || create!(
      expert_id: "luigi-sanierung-expert-001",
      name: "Luigi",
      domain: "construction_renovation",
      years_experience: 30,
      specializations: ["bathroom_renovation", "kitchen_renovation", "heating_systems", "insulation"]
    )
  end
  
  def total_knowledge_entities
    knowledge.count
  end
  
  def expertise_areas
    knowledge.group(:entity_type).count
  end
end