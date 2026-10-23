class CreateOwnerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :owner_profiles do |t|
      %w[name headline greeting career].each do |col|
        %w[ko en vi ja].each { |l| t.text :"#{col}_#{l}" }
      end
      t.integer :years_of_experience, null: false, default: 30
      t.timestamps
    end
  end
end
