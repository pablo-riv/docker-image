class AddEmailsNotificationToEntities < ActiveRecord::Migration[5.0]
  def change
    add_column :entities, :email_notification, :string
    add_column :entities, :email_commercial, :string
  end
end
