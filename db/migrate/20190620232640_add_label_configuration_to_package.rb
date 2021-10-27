class AddLabelConfigurationToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :label, :json, default: { size: '4x4', pdf: '', epl: '', zpl: '', shipit: '' }
  end
end
