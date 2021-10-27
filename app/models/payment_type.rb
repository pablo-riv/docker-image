class PaymentType < ApplicationRecord
  # RELATIONS
  has_many :courier_payment_types

  # VALIDATIONS
  validates :name, uniqueness: true

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
