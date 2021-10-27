class Commune < ApplicationRecord
  # CONSTANTS
  COURIERS = %w[starken chilexpress correoschile dhl muvsmart shippify].freeze

  # OOP
  include Filterable

  # RELATIONS
  belongs_to :region
  accepts_nested_attributes_for :region
  validates :name, uniqueness: { scope: :region_id }
  has_one :cutting_hour, as: :cutting
  has_many :courier_origins
  has_many :courier_destinies
  has_many :translate_communes_couriers

  # DELEGATORS
  delegate :name, to: :region, allow_nil: true, prefix: 'region'
  delegate :country_name, to: :region, allow_nil: true

  # TYPES
  store :cutting_hours, accessors: %i(pp ff ll)

  # CLASS METHODS
  scope :with_region_id, ->(id) { where(region_id: id) }
  scope :code_starts_with, ->(code) { where('code like ?', code) }
  scope :availables, -> { where(is_available: true) }
  scope :order_by_name, -> { order(name: :asc) }

  def self.allowed_attributes
    [:region_id, :name, :is_available, :code, :pp, :ff, :ll, couriers_availables: [:starken, :chilexpress, :correoschile, :dhl, :muvsmart, :chileparcels, :shippify]]
  end

  def self.by_type(type)
    type.include?('branch_offices') ? where(is_available: true) : all
  end

  def available_for(courier_name)
    couriers_availables[courier_name].blank? ? false : true
  end
end
