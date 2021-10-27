class CouriersBranchOffice < ApplicationRecord
  # RELATIONS
  belongs_to :courier
  belongs_to :commune

  #VALIDATIONS
  validates :name, presence: true

  #SCOPES
  default_scope { where(deleted_at: nil) }
end
