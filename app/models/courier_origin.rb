class CourierOrigin < ApplicationRecord
  # RELATIONS
  belongs_to :courier
  belongs_to :commune

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
