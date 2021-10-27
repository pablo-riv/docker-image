class AddMaxSecureToPurchase < ActiveRecord::Migration[5.0]
  def change
    change_column_default(:packages, :purchase, from: { detail: '',
                                                        amount: 0,
                                                        ticket_number: '',
                                                        extra_insurance: false,
                                                        insurance_price: 0.0 },
                                                to: { detail: '',
                                                      amount: 0,
                                                      ticket_number: '',
                                                      extra_insurance: false,
                                                      insurance_price: 0.0,
                                                      max_insurance: 0.0 })
  end
end
