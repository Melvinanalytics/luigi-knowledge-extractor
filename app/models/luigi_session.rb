# == Schema Information  
# Table name: luigi_sessions
#   id                     :uuid             not null, primary key
#   luigi_expert_id       :uuid             not null, foreign_key
#   session_name          :string
#   description           :text
#   status                :string           default("active")
#   total_messages        :integer          default(0)
#   entities_extracted    :integer          default(0) 
#   relationships_created :integer          default(0)
#   avg_confidence        :decimal(3,2)     default(0.00)
#   started_at            :datetime         not null
#   ended_at              :datetime
#   metadata              :jsonb            default({})

class LuigiSession < ApplicationRecord
  belongs_to :luigi_expert
  has_many :luigi_messages, dependent: :destroy
  has_many :luigi_entities, dependent: :destroy
  has_many :luigi_relationships, dependent: :destroy
  
  validates :status, inclusion: { in: %w[active paused completed] }
  validates :started_at, presence: true
  
  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(started_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  
  def duration_seconds
    end_time = ended_at || Time.current
    (end_time - started_at).to_i
  end
  
  def duration_formatted
    seconds = duration_seconds
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    
    if hours > 0
      "#{hours}h #{minutes}m #{secs}s"
    elsif minutes > 0
      "#{minutes}m #{secs}s"
    else
      "#{secs}s"
    end
  end
  
  def update_statistics!
    update!(
      total_messages: luigi_messages.count,
      entities_extracted: luigi_entities.count,
      relationships_created: luigi_relationships.count,
      avg_confidence: luigi_messages.where('confidence_score > 0').average(:confidence_score) || 0.0
    )
  end
  
  def complete!
    update!(
      status: 'completed',
      ended_at: Time.current
    )
    update_statistics!
  end
  
  def knowledge_density
    return 0.0 if total_messages.zero?
    
    (entities_extracted + relationships_created).to_f / total_messages
  end
end