FactoryBot.define do
  factory :luigi_message do
    association :luigi_session
    message_type { "user" }
    content { "Das ist eine Testmessage über Bausanierung." }
    confidence_score { 0.8 }
    entities_extracted { 3 }
    processing_time_ms { 1500 }
    metadata { { concepts_found: ["bathroom", "tiles"], extraction_summary: "Test extraction" } }
    created_at { Time.current }

    trait :assistant do
      message_type { "assistant" }
      content { "Das ist interessant! Erzähl mir mehr darüber." }
    end

    trait :system do
      message_type { "system" }
      content { "Hallo Luigi! Schön dich zu sehen." }
      confidence_score { 1.0 }
    end

    trait :with_entities do
      after(:create) do |message|
        create_list(:luigi_entity, 2, luigi_message: message)
      end
    end
  end
end