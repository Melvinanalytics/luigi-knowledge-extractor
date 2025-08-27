class CreateLuigiSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :luigi_sessions, id: :uuid do |t|
      t.references :luigi_expert, null: false, foreign_key: true, type: :uuid
      t.string :session_name
      t.text :description
      t.string :status, default: 'active'
      t.integer :total_messages, default: 0
      t.integer :entities_extracted, default: 0
      t.integer :relationships_created, default: 0
      t.decimal :avg_confidence, precision: 3, scale: 2, default: 0.00
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :luigi_sessions, :status
    add_index :luigi_sessions, :started_at
    add_index :luigi_sessions, :metadata, using: :gin
  end
end