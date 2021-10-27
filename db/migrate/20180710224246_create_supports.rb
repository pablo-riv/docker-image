class CreateSupports < ActiveRecord::Migration[5.0]
  def change
    create_table :supports do |t|
      t.string :kind
      t.string :priority
      t.string :url
      t.string :status
      t.string :subject
      t.string :assignee_id
      t.string :assignee_email
      t.string :messages
      t.string :provider_id
      t.integer :package_id
      t.string :package_reference
      t.string :package_tracking
      t.string :via
      t.string :other_subject
      t.references :account, foreign_key: true, index: true

      t.timestamps
    end
  end
end
