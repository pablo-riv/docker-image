class PackagesPickup < ApplicationRecord
  acts_as_paranoid

  belongs_to :package
  belongs_to :pickup
end
