class Return < ApplicationRecord
  # RELATIONS
  has_one :address_book, as: :addressable
  belongs_to :company

  # VALIDATIONS
  accepts_nested_attributes_for :address_book
  validates_presence_of :name
  validates :address_book, presence: true

  # SCOPES
  def self.allowed_attributes
    [:name, address_book_attributes: AddressBook.allowed_attributes]
  end
end
