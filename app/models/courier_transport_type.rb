class CourierTransportType < ApplicationRecord
  # RELATIONS
  belongs_to :courier
  belongs_to :transport_type

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
