class Check < ApplicationRecord
  belongs_to :package

  validates_uniqueness_of :package_id, if: :valid_in?, on: :create
  def self.in_allowed_attributes
    [:id, :package_id, in: [:created_at, :hero, :shipit_code, :branch_office_id, :courier, :craftsman]]
  end

  def self.out_allowed_attributes
    [:id, :package_id, out: [:created_at, :shipit_code, :courier, :branch_office_id, :tracking_number, :craftsman, :packing_quantity, :packing_left_quantity]]
  end

  def valid_in?
    checks = Check.where(package_id: package_id, created_at: (Time.current.at_beginning_of_day..Time.current.at_end_of_day))
    checks.blank? ? true : false
  end

  def in_created_at
    self.in['created_at'].to_datetime - 3.hours
  end

  def out_created_at
    self.out['created_at'].present? ? (self.out['created_at'].to_datetime - 3.hours) : ''
  end
end
