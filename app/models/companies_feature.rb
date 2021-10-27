class CompaniesFeature < ApplicationRecord
  ## RELATIONS
  belongs_to :company
  belongs_to :feature
  
  ## ATTRIBUTES

  ## CLASS METHODS
  def self.allowed_attributes
    [:company_id, :feature_id, :price]
  end
  ## PUBLIC METHODS
  ## PRIVATE METHODS
end