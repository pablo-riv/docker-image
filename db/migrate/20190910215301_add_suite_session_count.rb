class AddSuiteSessionCount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :suite_sessions, :integer, default: 0
  end
end
