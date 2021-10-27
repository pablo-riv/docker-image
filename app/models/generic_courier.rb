class GenericCourier < ApplicationRecord
  #VALIDATIONS
  validates :name, uniqueness: true
  has_many :couriers

  #SCOPES
  default_scope { where(deleted_at: nil) }
end
