class AddRescheduleToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :reschedule, :jsonb, default: { updates: 0,
                                                         user_id: nil,
                                                         updated_at: nil,
                                                         old_operation_date: nil }
  end
end
