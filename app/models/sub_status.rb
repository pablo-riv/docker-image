class SubStatus < ApplicationRecord
  # RELATIONS
  has_and_belongs_to_many :management_steps
end
