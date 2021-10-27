class AddNpsScoreToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :nps_score, :integer
  end
end
