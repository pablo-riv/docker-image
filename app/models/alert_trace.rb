class AlertTrace < ApplicationRecord
  acts_as_paranoid

  # RELATIONS
  belongs_to :alert
end
