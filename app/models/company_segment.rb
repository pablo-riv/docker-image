class CompanySegment < ApplicationRecord
  # RELATIONS
  has_many :retention_companies, class_name: 'Company', foreign_key: :retention_segment_id
  has_many :acquisition_companies, class_name: 'Company', foreign_key: :acquisition_segment_id

  # VALIDATIONS
  validates_presence_of %i(shipments_min shipments_max name)
end
