require 'rails_helper'

RSpec.describe LuigiExpert, type: :model do
  describe 'validations' do
    subject { build(:luigi_expert) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:years_experience).is_greater_than(0) }
    it { should validate_inclusion_of(:active).in_array([true, false]) }
  end

  describe 'associations' do
    it { should have_many(:luigi_sessions).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:active_expert) { create(:luigi_expert, active: true) }
    let!(:inactive_expert) { create(:luigi_expert, :inactive) }

    it 'filters active experts' do
      expect(LuigiExpert.active).to include(active_expert)
      expect(LuigiExpert.active).not_to include(inactive_expert)
    end
  end

  describe '#avg_session_confidence' do
    let(:expert) { create(:luigi_expert) }
    let(:session) { create(:luigi_session, luigi_expert: expert) }

    before do
      create(:luigi_message, luigi_session: session, confidence_score: 0.8)
      create(:luigi_message, luigi_session: session, confidence_score: 0.6)
    end

    it 'calculates average confidence across all sessions' do
      expect(expert.avg_session_confidence).to eq(0.7)
    end
  end

  describe '#total_entities_extracted' do
    let(:expert) { create(:luigi_expert) }
    let(:session) { create(:luigi_session, luigi_expert: expert) }

    before do
      create(:luigi_message, luigi_session: session, entities_extracted: 5)
      create(:luigi_message, luigi_session: session, entities_extracted: 3)
    end

    it 'sums entities across all sessions' do
      expect(expert.total_entities_extracted).to eq(8)
    end
  end

  describe '#experience_level' do
    it 'returns beginner for less than 5 years' do
      expert = build(:luigi_expert, years_experience: 3)
      expect(expert.experience_level).to eq('beginner')
    end

    it 'returns intermediate for 5-15 years' do
      expert = build(:luigi_expert, years_experience: 10)
      expect(expert.experience_level).to eq('intermediate')
    end

    it 'returns expert for more than 15 years' do
      expert = build(:luigi_expert, years_experience: 25)
      expect(expert.experience_level).to eq('expert')
    end
  end
end