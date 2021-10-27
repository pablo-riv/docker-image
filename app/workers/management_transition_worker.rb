class ManagementTransitionWorker
  include Sneakers::Worker
  from_queue 'core.management_transition'

  PERMITTED_COURIERS = %w[bluexpress chilexpress starken muvsmart motopartner].freeze

  def work(data)
    package = Package.find_by(id: JSON.parse(data)['package_id'])
    package_sub_status = JSON.parse(data)['sub_status']
    raise ProactiveMonitoring::Errors::PackageNotFound if package.blank?
    raise ProactiveMonitoring::Errors::UnpermittedCourier unless PERMITTED_COURIERS.include? package.courier_for_client.downcase
    raise ProactiveMonitoring::Errors::PackageSubStatusNotFound if package_sub_status.blank?

    management_step = ManagementStep.find_by(name: 'service_on_hold')
    service_on_hold_statuses = management_step.sub_statuses.pluck(:name)

    return service_on_hold(package, management_step) if service_on_hold_statuses.include?(package_sub_status) && package.shipping_managements.blank?
    raise ProactiveMonitoring::Errors::ShippingManagementNotFound if package.try(:shipping_managements).blank?

    # Current management
    shipping_management = package.shipping_managements.last
    sub_status = SubStatus.find_by(name: package_sub_status)
    # If sub_status are not mapping
    raise ProactiveMonitoring::Errors::SubStatusNotMapped if sub_status.blank?

    # Last step in management
    last_step = shipping_management.management_processes.last.management_step.name
    # if keeping in the same step or doesn't have a management step associate to the sub status
    raise ProactiveMonitoring::Errors::KeepShippingState if sub_status.management_steps.blank? || last_step == sub_status.management_steps.last.name

    ManagementProcess.create(shipping_management: shipping_management,
                             management_step: sub_status.management_steps.last)

    ack!
  rescue StandardError => _e
    ack!
  end

  def service_on_hold(package, management_step)
    shipping_management = package.shipping_managements.create(kind: 0,
                                                              status: 0)
    ManagementProcess.create(shipping_management: shipping_management,
                             management_step: management_step)
    ack!
  end
end
