class ManagementStep < ApplicationRecord
  # RELATIONS
  has_and_belongs_to_many :sub_statuses
  has_many :management_processes
end
