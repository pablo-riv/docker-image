class Status < ApplicationRecord
  acts_as_paranoid

  # RELATIONS
  belongs_to :tracking
  belongs_to :sub_status
end
