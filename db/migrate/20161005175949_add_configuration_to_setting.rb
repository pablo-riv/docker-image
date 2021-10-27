class AddConfigurationToSetting < ActiveRecord::Migration[5.0]
  def change
    add_column :settings, :configuration, :json
  end
end
