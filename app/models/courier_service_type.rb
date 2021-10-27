class CourierServiceType < ApplicationRecord
  # RELATIONS
  belongs_to :courier

  # VALIDATIONS
  validates :name, uniqueness: true

  # SCOPES
  default_scope { where(deleted_at: nil) }
end
