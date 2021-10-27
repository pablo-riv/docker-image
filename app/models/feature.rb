class Feature < ApplicationRecord
  ## RELATIONS
  has_many :companies_features
  has_many :companies, through: :companies_features

  ## ATTRIBUTES

  ## CLASS METHODS
  def self.allowed_attributes
    [:name, :price]
  end
  ## PUBLIC METHODS
  ## PRIVATE METHODS
end
