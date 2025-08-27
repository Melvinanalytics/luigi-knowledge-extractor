class CreateLuigiMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :luigi_messages, id: :uuid do |t|
      t.references :luigi_session, null: false, foreign_key: true, type: :uuid
      t.string :message_type, null: false
      t.text :content, null: false
      t.decimal :confidence_score, precision: 3, scale: 2, default: 0.0
      t.integer :entities_extracted, default: 0
      t.integer :processing_time_ms, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :luigi_messages, :message_type
    add_index :luigi_messages, :created_at
    add_index :luigi_messages, :confidence_score
    add_index :luigi_messages, :metadata, using: :gin
  end
end