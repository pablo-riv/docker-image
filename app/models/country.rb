class Country < ApplicationRecord
  ## RELATIONS
  has_many :regions
  has_many :couriers
  has_many :communes, through: :regions
  has_many :countries_sellers
  has_many :sellers, through: :countries_sellers

  def self.ordered_by_availability
    order(is_available: :desc, name: :asc)
  end
end
