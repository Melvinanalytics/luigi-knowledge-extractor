# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 7) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "vector"

  create_table "luigi_entities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "luigi_session_id", null: false
    t.uuid "luigi_message_id", null: false
    t.string "entity_type", null: false
    t.string "entity_value", null: false
    t.decimal "confidence", precision: 3, scale: 2, null: false
    t.text "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confidence"], name: "index_luigi_entities_on_confidence"
    t.index ["entity_type", "entity_value"], name: "index_luigi_entities_on_entity_type_and_entity_value"
    t.index ["entity_type"], name: "index_luigi_entities_on_entity_type"
    t.index ["entity_value"], name: "index_luigi_entities_on_entity_value"
    t.index ["luigi_message_id"], name: "index_luigi_entities_on_luigi_message_id"
    t.index ["luigi_session_id"], name: "index_luigi_entities_on_luigi_session_id"
  end

  create_table "luigi_experts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "name", null: false
    t.string "expertise_domain", default: "construction_renovation"
    t.integer "years_experience", default: 30
    t.jsonb "specializations", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expertise_domain"], name: "index_luigi_experts_on_expertise_domain"
    t.index ["specializations"], name: "index_luigi_experts_on_specializations", using: :gin
    t.index ["user_id"], name: "index_luigi_experts_on_user_id", unique: true
  end

  create_table "luigi_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "luigi_session_id", null: false
    t.string "message_type", null: false
    t.text "content", null: false
    t.decimal "confidence_score", precision: 3, scale: 2, default: "0.0"
    t.integer "entities_extracted", default: 0
    t.integer "processing_time_ms", default: 0
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confidence_score"], name: "index_luigi_messages_on_confidence_score"
    t.index ["created_at"], name: "index_luigi_messages_on_created_at"
    t.index ["luigi_session_id"], name: "index_luigi_messages_on_luigi_session_id"
    t.index ["message_type"], name: "index_luigi_messages_on_message_type"
    t.index ["metadata"], name: "index_luigi_messages_on_metadata", using: :gin
  end

  create_table "luigi_relationships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "luigi_session_id", null: false
    t.uuid "luigi_message_id", null: false
    t.string "from_entity", null: false
    t.string "relation_type", null: false
    t.string "to_entity", null: false
    t.decimal "confidence", precision: 3, scale: 2, null: false
    t.text "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confidence"], name: "index_luigi_relationships_on_confidence"
    t.index ["from_entity", "relation_type", "to_entity"], name: "idx_luigi_relationships_triple"
    t.index ["from_entity"], name: "index_luigi_relationships_on_from_entity"
    t.index ["luigi_message_id"], name: "index_luigi_relationships_on_luigi_message_id"
    t.index ["luigi_session_id"], name: "index_luigi_relationships_on_luigi_session_id"
    t.index ["relation_type"], name: "index_luigi_relationships_on_relation_type"
    t.index ["to_entity"], name: "index_luigi_relationships_on_to_entity"
  end

  create_table "luigi_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "luigi_expert_id", null: false
    t.string "session_name"
    t.text "description"
    t.string "status", default: "active"
    t.integer "total_messages", default: 0
    t.integer "entities_extracted", default: 0
    t.integer "relationships_created", default: 0
    t.decimal "avg_confidence", precision: 3, scale: 2, default: "0.0"
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["luigi_expert_id"], name: "index_luigi_sessions_on_luigi_expert_id"
    t.index ["metadata"], name: "index_luigi_sessions_on_metadata", using: :gin
    t.index ["started_at"], name: "index_luigi_sessions_on_started_at"
    t.index ["status"], name: "index_luigi_sessions_on_status"
  end

  add_foreign_key "luigi_entities", "luigi_messages"
  add_foreign_key "luigi_entities", "luigi_sessions"
  add_foreign_key "luigi_messages", "luigi_sessions"
  add_foreign_key "luigi_relationships", "luigi_messages"
  add_foreign_key "luigi_relationships", "luigi_sessions"
  add_foreign_key "luigi_sessions", "luigi_experts"
end
