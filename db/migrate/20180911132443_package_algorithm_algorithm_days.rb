class PackageAlgorithmAlgorithmDays < ActiveRecord::Migration[5.0]
  def change
	add_column :packages, :algorithm, :integer, default: 1
	add_column :packages, :algorithm_days, :integer, null: true
  end
end
