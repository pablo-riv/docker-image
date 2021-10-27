class Region < ApplicationRecord
  include Filterable
  ## RELATIONS
  has_many :communes
  belongs_to :country

  validates :name, uniqueness: true

  delegate :name, to: :country, allow_nil: true, prefix: true

  accepts_nested_attributes_for :communes
end
