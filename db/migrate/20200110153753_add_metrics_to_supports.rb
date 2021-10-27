class AddMetricsToSupports < ActiveRecord::Migration[5.0]
  def change
    add_column :supports, :requester_email, :string, default: ''
    add_column :supports, :description, :string, default: ''
    add_column :supports, :group_name, :string, default: ''
    add_column :supports, :metrics, :json, default: {}
  end
end
