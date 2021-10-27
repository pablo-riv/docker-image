class AddASetupFlowToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :setup_flow, :json, default: { commercial: '',
                                                          administrative: '',
                                                          operative: '',
                                                          plan: '' }
  end
end
