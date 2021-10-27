class ManagementProcess < ApplicationRecord
  # RELATIONS
  belongs_to :shipping_management
  belongs_to :management_step

  after_create :update_started_at
  after_create :create_incidence, if: :service_on_hold?

  delegate :package, to: :shipping_management
  delegate :name, to: :management_step, prefix: :step

  private

  def update_started_at
    update_columns(started_at: DateTime.current)
  end

  def service_on_hold?
    management_step.name == 'service_on_hold'
  end

  def create_incidence
    return if shipping_management.with_service_on_hold? && package.incidences.present?

    create_wrong_address_incidence if %w[unexisting_address incomplete_address].include?(package.sub_status)
    create_lost_parcel_incidence if package.sub_status == 'strayed'
  end

  def create_wrong_address_incidence
    address = package.address.dup
    address.update(package_id: nil)
    wrong_address = WrongAddress.create(full_name: package.full_name,
                                        phone: package.cellphone,
                                        address_id: address.id)
    Incidence.create(package_id: package.id,
                     status: 0,
                     subject: I18n.t('activerecord.attributes.incidence.subject.wrong_address'),
                     actable_id: wrong_address.id,
                     actable_type: 'WrongAddress')
  end

  def create_lost_parcel_incidence
    refund = Refund.create(refund_params)
    lost_parcel = LostParcel.create(refund_id: refund.id)
    Incidence.create(package_id: package.id,
                     status: 0,
                     subject: I18n.t('activerecord.attributes.incidence.subject.lost_parcel'),
                     actable_id: lost_parcel.id,
                     actable_type: 'LostParcel')
  end

  def refund_params
    courier = package&.courier_for_client == 'muvsmart' ? 'ninety_nine_minutes' : package&.courier_for_client
    {
      package_id: package.id,
      invoice_number: package&.insurance&.ticket_number || '',
      motive: 'strayed',
      assignee_id: 1,
      assignee_type: 'account',
      responsible: courier || 'shipit',
      content_price: package&.insurance&.ticket_amount || 0,
      shipping_price: package&.shipping_price || 0,
      overcharge_price: package.is_payable ? package&.shipping_price : 0,
      total_refund: package&.insurance&.ticket_amount.to_i + package&.shipping_price.to_i,
      status: 'pending',
      date: DateTime.current.to_date
    }
  end
end
