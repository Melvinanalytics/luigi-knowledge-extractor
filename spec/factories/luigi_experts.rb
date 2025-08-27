FactoryBot.define do
  factory :luigi_expert do
    user_id { SecureRandom.uuid }
    name { "Luigi" }
    years_experience { 30 }
    specializations { ["bathroom_renovation", "kitchen_renovation", "heating_systems"] }
    expertise_domain { "construction_renovation" }
    active { true }
    created_at { 1.hour.ago }
    updated_at { 1.hour.ago }

    trait :inactive do
      active { false }
    end

    trait :beginner do
      years_experience { 5 }
      name { "Junior Luigi" }
    end
  end
end