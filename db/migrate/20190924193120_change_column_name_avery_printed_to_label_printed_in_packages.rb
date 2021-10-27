class ChangeColumnNameAveryPrintedToLabelPrintedInPackages < ActiveRecord::Migration[5.0]
  def change
    rename_column :packages, :avery_printed, :label_printed
  end
end
