class CourierInsuranceConfiguration < ApplicationRecord
  # RELATIONS
  belongs_to :courier

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
