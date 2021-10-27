class CreateBranchOffices < ActiveRecord::Migration[5.0]
  def change
    create_table :branch_offices do |t|
      t.integer :company_id

      t.timestamps
    end
    add_index :branch_offices, :company_id
  end
end
