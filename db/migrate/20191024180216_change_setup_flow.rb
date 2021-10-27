class ChangeSetupFlow < ActiveRecord::Migration[5.0]
  def change
    remove_column :companies, :setup_flow
    add_column :companies, :commercial_flow, :string
    add_column :companies, :administrative_flow, :string
    add_column :companies, :operative_flow, :string
    add_column :companies, :plan_flow, :string
  end
end
