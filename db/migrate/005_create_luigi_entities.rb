class CreateLuigiEntities < ActiveRecord::Migration[7.1]
  def change
    create_table :luigi_entities, id: :uuid do |t|
      t.references :luigi_session, null: false, foreign_key: true, type: :uuid
      t.references :luigi_message, null: false, foreign_key: true, type: :uuid
      t.string :entity_type, null: false
      t.string :entity_value, null: false
      t.decimal :confidence, precision: 3, scale: 2, null: false
      t.text :context

      t.timestamps
    end

    add_index :luigi_entities, :entity_type
    add_index :luigi_entities, :entity_value
    add_index :luigi_entities, :confidence
    add_index :luigi_entities, [:entity_type, :entity_value]
  end
end