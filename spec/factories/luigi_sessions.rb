FactoryBot.define do
  factory :luigi_session do
    association :luigi_expert
    session_name { "Luigi Session #{Time.current.strftime('%Y-%m-%d %H:%M')}" }
    description { "Knowledge extraction session for construction renovation expertise" }
    status { "active" }
    started_at { Time.current }
    ended_at { nil }

    trait :completed do
      status { "completed" }
      ended_at { 1.hour.from_now }
    end

    trait :with_messages do
      after(:create) do |session|
        create_list(:luigi_message, 3, luigi_session: session)
      end
    end
  end
end