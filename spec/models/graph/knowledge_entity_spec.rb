require 'rails_helper'

RSpec.describe Graph::KnowledgeEntity, type: :model do
  describe 'validations' do
    subject { described_class.new(value: "Test Entity", entity_type: "Material") }

    it 'validates presence of value' do
      subject.value = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:value]).to include("can't be blank")
    end

    it 'validates presence of entity_type' do
      subject.entity_type = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:entity_type]).to include("can't be blank")
    end
  end

  describe '.find_or_create_with_mention' do
    context 'when entity does not exist' do
      it 'creates a new entity with correct attributes' do
        entity = described_class.find_or_create_with_mention(
          "Ceramic Tiles", "Material", 0.85, "bathroom renovation context"
        )

        expect(entity).to be_persisted
        expect(entity.value).to eq("Ceramic Tiles")
        expect(entity.entity_type).to eq("Material")
        expect(entity.confidence).to eq(0.85)
        expect(entity.mention_count).to eq(1)
        expect(entity.context).to eq("bathroom renovation context")
      end

      it 'normalizes confidence to valid range' do
        entity = described_class.find_or_create_with_mention(
          "Test Entity", "Material", 1.5
        )
        expect(entity.confidence).to eq(1.0)

        entity2 = described_class.find_or_create_with_mention(
          "Test Entity 2", "Material", -0.5
        )
        expect(entity2.confidence).to eq(0.0)
      end

      it 'strips whitespace from value and entity_type' do
        entity = described_class.find_or_create_with_mention(
          "  Ceramic Tiles  ", "  Material  ", 0.85
        )
        expect(entity.value).to eq("Ceramic Tiles")
        expect(entity.entity_type).to eq("Material")
      end
    end

    context 'when entity already exists' do
      let!(:existing_entity) do
        described_class.create!(
          value: "Ceramic Tiles",
          entity_type: "Material", 
          confidence: 0.7,
          mention_count: 1,
          context: "original context"
        )
      end

      it 'updates existing entity with higher confidence' do
        updated_entity = described_class.find_or_create_with_mention(
          "Ceramic Tiles", "Material", 0.9, "new context"
        )

        expect(updated_entity.id).to eq(existing_entity.id)
        expect(updated_entity.confidence).to eq(0.9) # Should use max, not average
        expect(updated_entity.mention_count).to eq(2)
        expect(updated_entity.context).to eq("new context")
      end

      it 'keeps existing higher confidence when new confidence is lower' do
        updated_entity = described_class.find_or_create_with_mention(
          "Ceramic Tiles", "Material", 0.5
        )

        expect(updated_entity.confidence).to eq(0.7) # Should keep higher confidence
        expect(updated_entity.mention_count).to eq(2)
      end

      it 'keeps existing context when new context is nil' do
        updated_entity = described_class.find_or_create_with_mention(
          "Ceramic Tiles", "Material", 0.8, nil
        )

        expect(updated_entity.context).to eq("original context")
      end
    end

    context 'with invalid parameters' do
      it 'returns nil when value is blank' do
        entity = described_class.find_or_create_with_mention("", "Material", 0.8)
        expect(entity).to be_nil

        entity2 = described_class.find_or_create_with_mention(nil, "Material", 0.8)
        expect(entity2).to be_nil
      end

      it 'returns nil when entity_type is blank' do
        entity = described_class.find_or_create_with_mention("Test", "", 0.8)
        expect(entity).to be_nil

        entity2 = described_class.find_or_create_with_mention("Test", nil, 0.8)
        expect(entity2).to be_nil
      end
    end
  end

  describe '#related_entities_count' do
    let(:entity) { create_entity("Central Entity", "Material") }
    let(:related_entity1) { create_entity("Related 1", "Tool") }
    let(:related_entity2) { create_entity("Related 2", "Method") }

    before do
      # Note: This would require actual Neo4j relationships to test properly
      # This is a simplified test structure
      allow(entity).to receive(:relates_to).and_return(double(count: 1))
      allow(entity).to receive(:related_from).and_return(double(count: 1))
    end

    it 'counts both outgoing and incoming relationships' do
      expect(entity.related_entities_count).to eq(2)
    end
  end

  private

  def create_entity(value, type, confidence = 0.8)
    described_class.create!(
      value: value,
      entity_type: type,
      confidence: confidence,
      mention_count: 1
    )
  end
end