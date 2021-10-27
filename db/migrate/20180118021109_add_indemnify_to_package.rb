class AddIndemnifyToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column(:packages, :with_purchase_insurance, :boolean, default: false)
    add_column(:packages, :purchase, :jsonb, default: { detail: '',
                                                        amount: '',
                                                        ticket_number: '',
                                                        extra_insurance: false,
                                                        insurance_price: 0.0 })
  end
end
