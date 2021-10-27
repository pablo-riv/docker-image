class PackageMassiveJob < ApplicationJob
  queue_as :shipments

  def perform(object)
    shipments = Package.massive_create(object)
    raise shipments if shipments.present? && shipments.is_a?(String)

    PackageService.select_availables_to_get_price(shipments).each(&:set_price)
  end
end
