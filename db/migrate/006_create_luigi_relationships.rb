class CreateLuigiRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :luigi_relationships, id: :uuid do |t|
      t.references :luigi_session, null: false, foreign_key: true, type: :uuid
      t.references :luigi_message, null: false, foreign_key: true, type: :uuid
      t.string :from_entity, null: false
      t.string :relation_type, null: false
      t.string :to_entity, null: false
      t.decimal :confidence, precision: 3, scale: 2, null: false
      t.text :context

      t.timestamps
    end

    add_index :luigi_relationships, :from_entity
    add_index :luigi_relationships, :to_entity
    add_index :luigi_relationships, :relation_type
    add_index :luigi_relationships, :confidence
    add_index :luigi_relationships, [:from_entity, :relation_type, :to_entity], name: 'idx_luigi_relationships_triple'
  end
end