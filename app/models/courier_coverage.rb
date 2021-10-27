class CourierCoverage < ApplicationRecord
  # RELATIONS
  belongs_to :courier_service_type
  belongs_to :courier_payment_type
  belongs_to :courier_transport_type
  belongs_to :courier_delivery_type
  belongs_to :courier_origin
  belongs_to :courier_destiny

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
