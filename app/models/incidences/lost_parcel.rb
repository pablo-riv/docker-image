class LostParcel < ApplicationRecord
  # RELATIONS
  belongs_to :refund
  has_one :incidence, as: :actable
  belongs_to :actable, polymorphic: true
end
