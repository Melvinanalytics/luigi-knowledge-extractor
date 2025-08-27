class CreateLuigiExperts < ActiveRecord::Migration[7.1]
  def change
    create_table :luigi_experts, id: :uuid do |t|
      t.string :user_id, null: false
      t.string :name, null: false
      t.string :expertise_domain, default: 'construction_renovation'
      t.integer :years_experience, default: 30
      t.jsonb :specializations, default: []

      t.timestamps
    end

    add_index :luigi_experts, :user_id, unique: true
    add_index :luigi_experts, :expertise_domain
    add_index :luigi_experts, :specializations, using: :gin
  end
end