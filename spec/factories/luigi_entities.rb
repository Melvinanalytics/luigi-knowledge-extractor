FactoryBot.define do
  factory :luigi_entity do
    association :luigi_message
    association :luigi_session
    entity_type { "Material" }
    entity_value { "Ceramic tiles" }
    confidence { 0.85 }
    context { "Mentioned in bathroom renovation context" }
    created_at { Time.current }

    trait :tool do
      entity_type { "Tool" }
      entity_value { "Tile cutter" }
    end

    trait :room_type do
      entity_type { "RoomType" }
      entity_value { "Bathroom" }
    end

    trait :cost do
      entity_type { "Cost" }
      entity_value { "€2000-3000" }
    end
  end
end