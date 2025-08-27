require 'rails_helper'

RSpec.describe KnowledgeExtractionService, type: :service do
  let(:session) { create(:luigi_session) }
  let(:message) { create(:luigi_message, luigi_session: session, content: "Ich renoviere gerade mein Badezimmer mit neuen Fliesen.") }
  let(:service) { described_class.new(message) }
  let(:openai_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
  end

  describe '#call' do
    let(:successful_extraction) do
      {
        "entities" => [
          {
            "type" => "RoomType",
            "value" => "Badezimmer", 
            "confidence" => 0.9,
            "context" => "renovation context"
          },
          {
            "type" => "Material",
            "value" => "Fliesen",
            "confidence" => 0.85,
            "context" => "bathroom renovation"
          }
        ],
        "relationships" => [
          {
            "from" => "Badezimmer",
            "to" => "Fliesen",
            "relation" => "USES",
            "confidence" => 0.8,
            "context" => "bathroom tiling"
          }
        ],
        "follow_up_questions" => [
          "Welche Art von Fliesen verwendest du?",
          "Wie groß ist dein Badezimmer?"
        ],
        "concepts" => ["Badezimmer", "Fliesen", "Renovation"],
        "summary" => "Luigi renoviert sein Badezimmer mit neuen Fliesen",
        "confidence" => 0.88
      }
    end

    context 'with successful OpenAI response' do
      before do
        allow(openai_client).to receive(:chat).and_return({
          "choices" => [
            {
              "message" => {
                "content" => successful_extraction.to_json
              }
            }
          ]
        })
      end

      it 'returns successful result' do
        result = service.call
        expect(result).to be_success
      end

      it 'creates entities correctly' do
        expect {
          service.call
        }.to change(LuigiEntity, :count).by(2)

        entities = LuigiEntity.last(2)
        expect(entities.map(&:entity_type)).to contain_exactly("RoomType", "Material")
        expect(entities.map(&:entity_value)).to contain_exactly("Badezimmer", "Fliesen")
      end

      it 'creates relationships correctly' do
        expect {
          service.call
        }.to change(LuigiRelationship, :count).by(1)

        relationship = LuigiRelationship.last
        expect(relationship.from_entity).to eq("Badezimmer")
        expect(relationship.to_entity).to eq("Fliesen")
        expect(relationship.relation_type).to eq("USES")
      end

      it 'enqueues graph update job' do
        expect(KnowledgeGraph::UpdateGraphJob).to receive(:perform_later)
        service.call
      end

      it 'generates assistant response' do
        expect {
          service.call
        }.to change(LuigiMessage, :count).by(1)

        response_message = LuigiMessage.where(message_type: 'assistant').last
        expect(response_message.content).to include("Badezimmer")
      end
    end

    context 'with malformed JSON response' do
      before do
        allow(openai_client).to receive(:chat).and_return({
          "choices" => [
            {
              "message" => {
                "content" => '```json\n{"entities": [{"type": "RoomType", "value": "Badezimmer"]]]\n```'
              }
            }
          ]
        })
      end

      it 'still returns successful result using fallback' do
        result = service.call
        expect(result).to be_success
      end

      it 'logs the parsing error' do
        expect(Rails.logger).to receive(:warn).with(/JSON parsing failed/)
        service.call
      end
    end

    context 'with empty OpenAI response' do
      before do
        allow(openai_client).to receive(:chat).and_return({
          "choices" => [
            {
              "message" => {
                "content" => ""
              }
            }
          ]
        })
      end

      it 'uses fallback extraction' do
        expect(Rails.logger).to receive(:error).with("Empty response from OpenAI")
        result = service.call
        expect(result).to be_success
      end
    end

    context 'when OpenAI API fails' do
      before do
        allow(openai_client).to receive(:chat).and_raise(StandardError.new("API Error"))
      end

      it 'uses fallback extraction' do
        expect(Rails.logger).to receive(:error).with(/Knowledge extraction failed/)
        result = service.call
        expect(result).to be_success
      end

      it 'still creates assistant response' do
        expect {
          service.call
        }.to change(LuigiMessage, :count).by(1)
      end
    end
  end

  describe '#parse_json_with_fallback' do
    context 'with valid JSON' do
      let(:valid_json) { '{"test": "value"}' }

      it 'parses correctly' do
        result = service.send(:parse_json_with_fallback, valid_json)
        expect(result).to eq({"test" => "value"})
      end
    end

    context 'with markdown-wrapped JSON' do
      let(:markdown_json) { '```json\n{"test": "value"}\n```' }

      it 'removes markdown and parses' do
        result = service.send(:parse_json_with_fallback, markdown_json)
        expect(result).to eq({"test" => "value"})
      end
    end

    context 'with unparseable content' do
      let(:bad_content) { 'This is not JSON at all and contains questions? Yes it does.' }

      it 'uses manual extraction as fallback' do
        result = service.send(:parse_json_with_fallback, bad_content)
        expect(result).to be_a(Hash)
        expect(result["entities"]).to be_an(Array)
        expect(result["relationships"]).to be_an(Array)
        expect(result["follow_up_questions"]).to include("Yes it does.")
      end
    end
  end

  describe '#normalize_extraction' do
    context 'with valid extraction hash' do
      let(:extraction) do
        {
          "entities" => [{"type" => "Material", "value" => "Tiles", "confidence" => 0.9}],
          "relationships" => [{"from" => "A", "to" => "B", "relation" => "USES", "confidence" => 0.8}],
          "concepts" => ["concept1", "concept2"],
          "confidence" => 0.85
        }
      end

      it 'normalizes correctly' do
        result = service.send(:normalize_extraction, extraction)
        
        expect(result["entities"]).to be_an(Array)
        expect(result["relationships"]).to be_an(Array)
        expect(result["follow_up_questions"]).to be_an(Array)
        expect(result["concepts"]).to be_an(Array)
        expect(result["confidence"]).to eq(0.85)
      end
    end

    context 'with invalid extraction (not a hash)' do
      it 'returns fallback extraction' do
        result = service.send(:normalize_extraction, "not a hash")
        expect(result["entities"]).to eq([])
        expect(result["confidence"]).to eq(0.0)
      end
    end
  end
end