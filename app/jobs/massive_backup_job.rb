class MassiveBackupJob < ApplicationJob
  queue_as :default

  def perform(packages, current_account, fulfillment = nil)
    Package.transaction do
      headquarter = current_account.entity_specific.default_branch_office
      packages.each do |package|
        new_package = headquarter.packages.build(package)
        new_package.from_backup = true
        puts "Nuevo package creado 💪:  #{new_package.to_json}" if new_package.save
        success = FulfillmentService.create_package(Package.generate_template_for(4, [new_package], current_account), current_account.entity_specific.id)
        raise 'Tuvimos un problema corroborando el stock de los SKU’s solicitados. intente denuevo más tarde.' unless success
      end
    end
  rescue StandardError => e
    puts "Hubo un problema intentando restaurar el backup de los pedidos: #{e.message.red}".red
  end
end
