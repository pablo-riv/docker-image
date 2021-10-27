class AddressBook < ApplicationRecord
  # CALLBACKS
  after_commit :check_default

  # RELATIONS
  belongs_to :addressable, polymorphic: true
  belongs_to :address
  belongs_to :company

  # VALIDATIONS
  accepts_nested_attributes_for :address
  validates_presence_of :full_name

  delegate :street, to: :address, allow_nil: true, prefix: 'address'
  delegate :number, to: :address, allow_nil: true, prefix: 'address'
  delegate :complement, to: :address, allow_nil: true, prefix: 'address'
  delegate :commune_id, to: :address, allow_nil: true, prefix: 'address'
  delegate :commune_name, to: :address, allow_nil: true, prefix: 'address'
  delegate :commune_region_name, to: :address, allow_nil: true, prefix: 'address'

  # SCOPES
  default_scope { where(archive: false) }

  def self.allowed_attributes
    [:full_name, :phone, :email, :default, :company_id, :addressable_type, :addressable_id, address_attributes: [:street, :number, :complement, :commune_id]]
  end

  private

  def check_default
    return unless self.default

    address_books = self.company.address_books.where(addressable_type: self.addressable_type).where.not(id: self.id)
    return true if address_books.size.zero?

    address_books.update_all(default: false)
  end
end
