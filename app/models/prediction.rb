class Prediction < ApplicationRecord
  # RELATIONS
  belongs_to :package
  # VALIDATIONS
  validates :package, presence: true
end
