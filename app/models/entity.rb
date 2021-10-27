class Entity < ApplicationRecord
  after_create :generate_relation
  ## RELATIONS
  has_many :accounts, dependent: :destroy
  belongs_to :address
  belongs_to :billing_address, class_name: :Address
  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :billing_address

  ## ACT AS SUPERCLASS
  actable

  validates_uniqueness_of :name, case_sensitive: false, scope: :actable_type, if: proc { |entity| entity.actable_type == 'Company' }

  default_scope { where(is_active: true) }
  scope :companies, -> { where(actable_type: 'Company') }
  scope :branch_offices, -> { where(actable_type: 'BranchOffice') }

  def self.allowed_attributes
    [:name, :run, :website, :commercial_business, :phone, :logo, :about, :email_contact, :contact_name, :is_active, :is_default, :email_notification, :email_commercial, address_attributes: []]
  end

  def update_address(address_params, branch_office)
    address = { street: address_params[:street],
                commune_id: address_params[:commune_id],
                number: address_params[:number],
                complement: address_params[:complement] }
    return false unless self.address.update_columns(address) && branch_office.acting_as.address.update_columns(address)
    NotifyMailer.company_change_address(branch_office.company).deliver
    CheckAreaBranchOfficeJob.perform_now(branch_office)
    Publisher.publish('change_trello_address', {address: address, branch_office: branch_office, commune: Commune.find(address_params[:commune_id])})
    true
  end

  def generate_relation
    return false if Rails.env.test?
    address = create_address
    billing_address =
      if actable_type == 'Company'
        b = create_address
        b.save(validate: false)
        b
      end
    update_columns(address_id: address.id, billing_address_id: billing_address.try(:id)) if address.save(validate: false)
  end

  def contact_info
    "#{contact_name} - #{phone}"
  end

  def default_account
    accounts.first.try(:serialize_data!)
  end
end
