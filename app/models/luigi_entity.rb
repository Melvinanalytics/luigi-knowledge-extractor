# == Schema Information
# Table name: luigi_entities
#   id                :uuid             not null, primary key
#   luigi_session_id  :uuid             not null, foreign_key
#   luigi_message_id  :uuid             not null, foreign_key
#   entity_type       :string           not null
#   entity_value      :string           not null
#   confidence        :decimal(3,2)     not null
#   context           :text
#   created_at        :datetime         not null
#   updated_at        :datetime         not null

class LuigiEntity < ApplicationRecord
  belongs_to :luigi_session
  belongs_to :luigi_message
  
  validates :entity_type, :entity_value, :confidence, presence: true
  validates :confidence, numericality: { in: 0.0..1.0 }
  validates :entity_type, inclusion: { 
    in: %w[
      BuildingType BuildingAge RoomType Damage Material Tool Method 
      Cost TimeFrame Risk Regulation Quality Brand Measurement
    ]
  }
  
  scope :by_type, ->(type) { where(entity_type: type) }
  scope :high_confidence, -> { where('confidence > ?', 0.8) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_value, ->(value) { where('entity_value ILIKE ?', "%#{value}%") }
  
  def confidence_percentage
    (confidence * 100).round
  end
  
  def self.entity_types_with_counts
    group(:entity_type).count.sort_by { |_, count| -count }
  end
  
  def self.most_mentioned_entities(limit = 10)
    group(:entity_value)
      .select('entity_value, COUNT(*) as mention_count, AVG(confidence) as avg_confidence')
      .order('mention_count DESC')
      .limit(limit)
  end
  
  def related_entities
    LuigiRelationship.joins(:luigi_message)
      .where(luigi_message: { luigi_session: luigi_session })
      .where('from_entity = ? OR to_entity = ?', entity_value, entity_value)
      .includes(:luigi_message)
  end
end