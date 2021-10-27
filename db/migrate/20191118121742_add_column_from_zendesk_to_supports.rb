class AddColumnFromZendeskToSupports < ActiveRecord::Migration[5.0]
  def change
    add_column :supports, :from_zendesk, :boolean, default: false
  end
end
