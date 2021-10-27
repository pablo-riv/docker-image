class CourierOperationalInformation < ApplicationRecord
  enum kind: { proactive_monitoring: 0, claim: 1 }
  # RELATIONS
  belongs_to :courier

  # VALIDATIONS
  validates_associated :courier
  validates :courier_id, :shipping_reference, :greeting, :main_email, presence: true
  validates :kind, inclusion: { in: kinds.keys, message: :inclusion_error }, presence: true
  validate :courier_id, if: :op_information_exist?, on: :create

  # CLASS METHODS
  def self.by_kind(kind = 'proactive_monitoring')
    where(kind: kind, is_active: true).includes(:courier)
  end

  def self.unique_by_kind(kind = 'proactive_monitoring')
    find_by(kind: kind, is_active: true)
  end

  def self.allowed_attributes
    [:courier_id, :greeting, :shipping_reference, :main_email, :kind, { emails: [] }]
  end

  private

  def op_information_exist?
    records = Courier.find(courier_id).courier_operational_informations
                     .where(kind: kind, is_active: true)
    errors.add(:courier_id, :bad_record) if records.present?
  end
end
