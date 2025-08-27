# == Schema Information
# Table name: luigi_messages
#   id                    :uuid             not null, primary key
#   luigi_session_id     :uuid             not null, foreign_key
#   message_type         :string           not null
#   content              :text             not null
#   confidence_score     :decimal(3,2)     default(0.0)
#   entities_extracted   :integer          default(0)
#   processing_time_ms   :integer          default(0)
#   metadata             :jsonb            default({})
#   created_at           :datetime         not null
#   updated_at           :datetime         not null

class LuigiMessage < ApplicationRecord
  belongs_to :luigi_session
  has_many :luigi_entities, dependent: :destroy
  has_many :luigi_relationships, dependent: :destroy
  
  validates :message_type, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true
  validates :confidence_score, numericality: { in: 0.0..1.0 }
  
  scope :by_type, ->(type) { where(message_type: type) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :high_confidence, -> { where('confidence_score > ?', 0.8) }
  scope :with_knowledge, -> { where('entities_extracted > 0') }
  
  after_create :update_session_stats
  
  def user_message?
    message_type == 'user'
  end
  
  def assistant_message?
    message_type == 'assistant'
  end
  
  def system_message?
    message_type == 'system'
  end
  
  def has_knowledge?
    entities_extracted > 0
  end
  
  def processing_time_formatted
    return "0ms" if processing_time_ms.zero?
    
    if processing_time_ms > 1000
      "#{(processing_time_ms / 1000.0).round(1)}s"
    else
      "#{processing_time_ms}ms"
    end
  end
  
  def confidence_percentage
    (confidence_score * 100).round
  end
  
  def follow_up_questions
    metadata['follow_up_questions'] || []
  end
  
  def concepts_found
    metadata['concepts_found'] || []
  end
  
  private
  
  def update_session_stats
    luigi_session.update_statistics!
  end
end