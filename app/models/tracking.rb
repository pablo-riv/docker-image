class Tracking < ApplicationRecord
  acts_as_paranoid

  # RELATIONS
  has_many :statuses, dependent: :destroy
  belongs_to :package
  belongs_to :courier
end
