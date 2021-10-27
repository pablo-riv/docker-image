class CourierDeliveryType < ApplicationRecord
  # RELATIONS
  belongs_to :courier
  belongs_to :delivery_type

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
