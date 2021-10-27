class Origin < ApplicationRecord
  # RELATIONS
  has_one :address_book, as: :addressable
  belongs_to :company
  belongs_to :branch_office

  # CALLBACKS
  after_commit :set_area_to_default

  # VALIDATIONS
  accepts_nested_attributes_for :address_book
  validates_presence_of :name
  validates :address_book, presence: true

  # SCOPES
  def self.allowed_attributes
    [:name, :branch_office_id, address_book_attributes: AddressBook.allowed_attributes]
  end

  def set_area_to_default
    return unless address_book.default
    return unless branch_office.present?
    return if branch_office.company_platform_version == 2

    CheckAreaBranchOfficeJob.perform_now(branch_office)
  end
end
