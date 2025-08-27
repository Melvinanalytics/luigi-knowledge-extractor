require 'rails_helper'

RSpec.describe LuigiSession, type: :model do
  describe 'validations' do
    subject { build(:luigi_session) }

    it { should validate_presence_of(:session_name) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[active completed paused]) }
  end

  describe 'associations' do
    it { should belong_to(:luigi_expert) }
    it { should have_many(:luigi_messages).dependent(:destroy) }
    it { should have_many(:luigi_entities).dependent(:destroy) }
    it { should have_many(:luigi_relationships).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:recent_session) { create(:luigi_session, created_at: 1.hour.ago) }
    let!(:old_session) { create(:luigi_session, created_at: 2.days.ago) }
    let!(:active_session) { create(:luigi_session, status: 'active') }
    let!(:completed_session) { create(:luigi_session, :completed) }

    it 'orders by most recent first' do
      expect(LuigiSession.recent.first).to eq(recent_session)
    end

    it 'filters active sessions' do
      expect(LuigiSession.active).to include(active_session)
      expect(LuigiSession.active).not_to include(completed_session)
    end
  end

  describe '#duration_seconds' do
    let(:session) { create(:luigi_session, started_at: 2.hours.ago, ended_at: 1.hour.ago) }

    it 'calculates duration between start and end' do
      expect(session.duration_seconds).to eq(3600) # 1 hour in seconds
    end

    context 'when session is not ended' do
      let(:session) { create(:luigi_session, started_at: 1.hour.ago, ended_at: nil) }

      it 'calculates duration from start to now' do
        expect(session.duration_seconds).to be_within(5).of(3600)
      end
    end
  end

  describe '#duration_formatted' do
    let(:session) { create(:luigi_session, started_at: 2.hours.ago, ended_at: 1.hour.ago) }

    it 'returns human readable duration' do
      expect(session.duration_formatted).to eq("1h 0m")
    end
  end

  describe '#total_messages' do
    let(:session) { create(:luigi_session) }

    before do
      create_list(:luigi_message, 3, luigi_session: session)
    end

    it 'counts associated messages' do
      expect(session.total_messages).to eq(3)
    end
  end

  describe '#entities_extracted' do
    let(:session) { create(:luigi_session) }

    before do
      create(:luigi_message, luigi_session: session, entities_extracted: 5)
      create(:luigi_message, luigi_session: session, entities_extracted: 3)
    end

    it 'sums entities from all messages' do
      expect(session.entities_extracted).to eq(8)
    end
  end

  describe '#avg_confidence' do
    let(:session) { create(:luigi_session) }

    before do
      create(:luigi_message, luigi_session: session, confidence_score: 0.8)
      create(:luigi_message, luigi_session: session, confidence_score: 0.6)
    end

    it 'calculates average confidence across messages' do
      expect(session.avg_confidence).to eq(0.7)
    end
  end
end