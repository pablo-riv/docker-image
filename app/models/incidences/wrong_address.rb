class WrongAddress < ApplicationRecord
  # RELATIONS
  has_one :incidence, as: :actable
  belongs_to :address
  belongs_to :actable, polymorphic: true
end
