# == Schema Information
# Table name: luigi_relationships
#   id                :uuid             not null, primary key
#   luigi_session_id  :uuid             not null, foreign_key
#   luigi_message_id  :uuid             not null, foreign_key
#   from_entity       :string           not null
#   relation_type     :string           not null
#   to_entity         :string           not null
#   confidence        :decimal(3,2)     not null
#   context           :text
#   created_at        :datetime         not null
#   updated_at        :datetime         not null

class LuigiRelationship < ApplicationRecord
  belongs_to :luigi_session
  belongs_to :luigi_message
  
  validates :from_entity, :relation_type, :to_entity, :confidence, presence: true
  validates :confidence, numericality: { in: 0.0..1.0 }
  validates :relation_type, inclusion: {
    in: %w[
      TYPICALLY_HAS REQUIRES COSTS TAKES_TIME CAUSES PREVENTS 
      COMPATIBLE_WITH BETTER_THAN USED_FOR MEASURED_BY LOCATED_IN
      REPLACED_BY IMPROVED_BY DAMAGED_BY
    ]
  }
  
  scope :by_type, ->(type) { where(relation_type: type) }
  scope :high_confidence, -> { where('confidence > ?', 0.8) }
  scope :involving_entity, ->(entity) { where('from_entity = ? OR to_entity = ?', entity, entity) }
  scope :from_entity, ->(entity) { where(from_entity: entity) }
  scope :to_entity, ->(entity) { where(to_entity: entity) }
  
  def confidence_percentage
    (confidence * 100).round
  end
  
  def formatted_triple
    "#{from_entity} → #{relation_type} → #{to_entity}"
  end
  
  def self.relation_types_with_counts
    group(:relation_type).count.sort_by { |_, count| -count }
  end
  
  def self.strongest_relationships(limit = 10)
    select('from_entity, relation_type, to_entity, AVG(confidence) as avg_confidence, COUNT(*) as mention_count')
      .group(:from_entity, :relation_type, :to_entity)
      .order('avg_confidence DESC, mention_count DESC')
      .limit(limit)
  end
  
  def self.knowledge_graph_data
    select('from_entity, relation_type, to_entity, confidence, context')
      .where('confidence > ?', 0.7)
      .includes(:luigi_message)
      .map do |rel|
        {
          source: rel.from_entity,
          target: rel.to_entity,
          relationship: rel.relation_type,
          confidence: rel.confidence,
          context: rel.context,
          session_id: rel.luigi_session_id
        }
      end
  end
end