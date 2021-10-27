class CourierPaymentType < ApplicationRecord
  # RELATIONS
  belongs_to :courier
  belongs_to :payment_type

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
