require 'rails_helper'

RSpec.describe KnowledgeGraph::UpdateGraphJob, type: :job do
  let(:session) { create(:luigi_session) }
  let(:message) { create(:luigi_message, luigi_session: session) }
  let(:extraction_data) do
    {
      "entities" => [
        {
          "type" => "Material",
          "value" => "Ceramic Tiles", 
          "confidence" => 0.9,
          "context" => "bathroom renovation"
        }
      ],
      "relationships" => [
        {
          "from" => "Bathroom",
          "to" => "Ceramic Tiles",
          "relation" => "USES",
          "confidence" => 0.8,
          "context" => "tiling work"
        }
      ]
    }
  end

  describe '#perform' do
    context 'with valid data' do
      it 'processes without raising errors' do
        expect {
          described_class.new.perform(session.id, message.id, extraction_data)
        }.not_to raise_error
      end

      it 'logs processing information' do
        expect(Rails.logger).to receive(:info).with(/Updating Neo4j graph/)
        expect(Rails.logger).to receive(:info).with(/Successfully updated Neo4j graph/)
        
        described_class.new.perform(session.id, message.id, extraction_data)
      end

      # Note: More comprehensive tests would require Neo4j test setup
      # This would include testing actual node creation and relationship building
    end

    context 'with invalid session id' do
      it 'handles ActiveRecord::RecordNotFound gracefully' do
        expect(Rails.logger).to receive(:error).with(/Record not found/)
        
        expect {
          described_class.new.perform(99999, message.id, extraction_data)
        }.not_to raise_error
      end
    end

    context 'with malformed extraction data' do
      let(:bad_data) { { "entities" => "not an array" } }

      it 'handles errors gracefully' do
        expect(Rails.logger).to receive(:info).with(/Successfully processed 0 out of/)
        
        expect {
          described_class.new.perform(session.id, message.id, bad_data)
        }.not_to raise_error
      end
    end
  end

  describe 'retry configuration' do
    it 'has proper retry settings for Neo4j errors' do
      retry_settings = described_class.retry_on_blocks

      expect(retry_settings).not_to be_empty
      # The exact structure depends on how ActiveJob stores retry configurations
    end
  end
end