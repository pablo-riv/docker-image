class ChangeDefaultValueOfSetupToCompany < ActiveRecord::Migration[5.0]
  def change
    change_column_default :companies, :setup_flow, from: { commercial: '',
                                                           administrative: '',
                                                           operative: '',
                                                           plan: '' },
                                                   to: { commercial: 'null',
                                                         administrative: 'null',
                                                         operative: 'null',
                                                         plan: 'null' }
  end
end
