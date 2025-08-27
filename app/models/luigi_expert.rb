# == Schema Information
# Table name: luigi_experts
#   id                    :uuid             not null, primary key
#   user_id              :string           not null, unique
#   name                 :string           not null
#   expertise_domain     :string           default("construction_renovation")
#   years_experience     :integer          default(30)
#   specializations      :jsonb            default([])
#   created_at           :datetime         not null
#   updated_at           :datetime         not null

class LuigiExpert < ApplicationRecord
  has_many :luigi_sessions, dependent: :destroy
  
  validates :user_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :years_experience, presence: true, numericality: { greater_than: 0 }
  
  scope :by_domain, ->(domain) { where(expertise_domain: domain) }
  scope :experienced, ->(min_years) { where('years_experience >= ?', min_years) }
  
  def self.luigi
    find_by(user_id: "luigi-sanierung-expert-001") || create_luigi!
  end
  
  def total_knowledge_sessions
    luigi_sessions.count
  end
  
  def total_messages_processed
    luigi_sessions.sum(:total_messages)
  end
  
  def avg_session_confidence
    luigi_sessions.where('avg_confidence > 0').average(:avg_confidence) || 0.0
  end
  
  private
  
  def self.create_luigi!
    create!(
      user_id: "luigi-sanierung-expert-001",
      name: "Luigi",
      expertise_domain: "construction_renovation", 
      years_experience: 30,
      specializations: ["bathroom_renovation", "kitchen_renovation", "heating_systems", "insulation"]
    )
  end
end