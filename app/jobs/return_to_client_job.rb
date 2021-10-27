class ReturnToClientJob < ApplicationJob
  queue_as :default

  def perform(ids)
    Package.where(id: ids).includes(:branch_office).each do |package|
      exist_return = Package.where(reference: "D#{package.reference[0..13]}",
                                   branch_office_id: package.branch_office_id).count
      next unless exist_return.zero?

      data = package.dup
      company = package.branch_office.company
      company_address = company.default_address
      data.reference_into_branch_office = "#{package.branch_office.name}_D#{data.reference[0..13]}"
      data.position = package.position
      data.father_id = package.father_id
      data.destiny = 'Domicilio'
      data.is_returned = true
      data.status = :in_preparation
      data.sub_status = ''
      data.full_name = company.current_account.full_name
      data.email = company.current_account.email
      data.cellphone = company.acting_as.phone
      data.courier_status = ''
      data.courier_status_updated_at = nil
      data.shipit_status_updated_at = nil
      data.tracking_number = ''
      data.packing = 'Sin empaque'
      data.shipping_price = 0
      data.total_price = 0
      data.shipping_cost = 0
      data.material_extra = 0
      data.courier_for_client = ''
      data.courier_selected = false
      data.created_at = nil
      data.updated_at = nil
      data.courier_url = nil
      data.url_pack = nil
      data.pack_pdf = nil
      data.delayed = false
      data.return_created_at = nil
      data.automatic_retry_date = nil
      data.trello_item = ''
      data.is_sized = false
      data.is_payable = false
      data.address_attributes = { street: company_address.street,
                                  number: company_address.number,
                                  complement: company_address.complement,
                                  commune_id: company_address.commune_id }

      data.api_shipping_price = 0
      data.api_shipping_cost = 0
      data.api_courier_client = nil
      data.api_courier_entity = nil
      data.api_packing_price = 0
      data.api_payable_price = 0
      data.api_total_price = 0
      data.api_updated_at = nil
      data.api_recalculate_price = false
      data.inventory_activity = nil
      data.spreadsheet_versions = nil
      data.spreadsheet_versions_destinations = nil
      data.platform = :from_return
      data.billing_date = nil

      data.save!
      package.update_columns(status: :returned, sub_status: 'returned', return_retry_date: DateTime.current)
      ReturnsMailer.client(company, package).deliver_now if Restriction.find_by(kind: 'available_return_emails').active
    end
  end
end
