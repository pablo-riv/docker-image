class Salesman < ApplicationRecord
  ## ACT AS USER
  acts_as :user

  def self.allowed_attributes
    User.allowed_attributes
  end
end
