class BeetrackRoute < ApplicationRecord
  # VALIDATIONS
  validates :route_id, presence: true
  validates :hero_id, presence: true
  validates :date, presence: true
end
