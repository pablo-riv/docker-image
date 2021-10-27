class PackageService
  def self.all_by_pickup(pickup)
    packages = Package.all_by_pickup(pickup)
    Publisher.publish('packages', packages)
  end

  def self.assign_values(package, branch_office, fulfillment, courier_branch_offices)
    package['branch_office_id'] = branch_office.id
    package['shipping_type'] = 'Normal' if package['shipping_type'] != 'Normal'
    package['is_payable'] = false unless package['is_payable'].present? || !package['is_payable'].blank?
    sizes = package['approx_size'].present? ? package['approx_size'].scan(/\d{2}x\d{2}x\d{2}/).first : nil
    sizes = sizes.nil? ? [] : sizes.split("x").map(&:to_f)
    package['height'] = package['height'].try(:to_f).try(:abs) || sizes.first || 10.0
    package['width'] = package['width'].try(:to_f).try(:abs) || sizes.second || 10.0
    package['length'] = package['length'].try(:to_f).try(:abs) || sizes.last || 10.0
    package['weight'] = package['weight'].try(:to_f).try(:abs) || 1.0
    package['courier_for_client'] = validate_courier_destiny(package)
    package['destiny'] = assign_destiny(package)
    package['courier_for_client'] = 'Starken' if fulfillment.present? && package['is_payable']
    package['courier_branch_office_id'] = change_courier_destiny(courier_branch_offices, package) if courier_branch_office_destiny?(package)

    package['insurance_attributes'] = insurance(package)
    package['reference_into_branch_office'] = "#{branch_office.name}_#{package['reference']}"

    (package.kind_of?(Hash) ? package : package.permit!).to_h
  end

  def self.algorithm_used(package = nil)
    default_name = "Algoritmo Shipit: más económico dentro de los mas rápidos"

    if !package['algorithm'].nil?

      if package['algorithm'].to_i == 1
        default_name
      elsif package['algorithm'].to_i == 2
        "Más barato a #{package['algorithm_days']} #{package['algorithm_days'].to_i == 1 ? 'día' : 'días'}"
      end

    else
      default_name
    end
  end

  def self.get_commune(package = nil)
    commune = Commune.find_by(name: package['address_attributes']['commune_id'].strip)
    package['address_attributes']['commune_id'] = commune.id if commune
    package
  end

  def self.set_communes(packages)
    if packages.first['address_attributes']['commune_id'].to_i <= 0
      packages.each do |package|
        get_commune(package)
      end
    end
    packages
  end

  def self.set_new_massive(packages, branch_office, fulfillment = {}, courier_branch_offices = [])
    result = packages.map do |package|
      begin
        package = HashWithIndifferentAccess.new(assign_values(package, branch_office, fulfillment, courier_branch_offices))
        raise "No has ingresado una comuna de destino para el envío: #{package[:reference]}" if package[:address_attributes][:commune_id].to_i.zero?
        raise "Nuestros couriers no llegan a destino pedido: #{package[:reference]}" unless validate_shipment(package)

        result = check(package, branch_office)
        result.persisted? ? result : nil
      rescue => e
        Rails::logger.info { "error: #{e.message}, \n backtrace: #{e.backtrace.join("\n")}" }
        Slack::Ti.new({}, {}).alert(nil, "Error al crear pedidos: #{e.message}\nBacktrace: #{e.backtrace[0]}\n", '#ti_alert')
        raise e.message
      end
    end
    result.compact
  end

  def self.check(params, branch_office)
    package = Package.unscoped.where(reference: params['reference'], branch_office_id: branch_office.id)
    raise "El pedido #{params['reference']} ya existe" if package.present?

    # New Business rule
    # Jira Card: https://shipitchile.atlassian.net/browse/APPS-554
    # requirement: https://docs.google.com/spreadsheets/d/10MVIQuw_PO9cwdahjXAe-750WJ_GFtQQwpCcYChHr_k/edit#gid=0&range=I37
    Package.create!(params)
  end

  def self.validate_courier_destiny(package)
    case package['destiny'].try(:downcase)
    when 'domicilio', 'sucursal' then package['courier_for_client']
    when 'sucursal chilexpress', 'chilexpress' then 'Chilexpress'
    when 'sucursal starken-turbus', 'starken-turbus', 'starken' then 'Starken'
    when 'dhl' then 'Dhl'
    when 'muvsmart' then 'MuvSmart'
    when 'correoschile', 'correos chile' then 'correoschile'
    when 'retiro cliente', 'despacho retail' then 'Fulfillment Delivery'
    when 'shippify' then 'Shippify'
    else
      ''
    end
  end

  def self.assign_destiny(package)
    case package['destiny'].try(:downcase)
    when 'domicilio' then 'domicilio'
    when 'retiro cliente', 'despacho retail' then package['destiny']
    when 'sucursal chilexpress', 'chilexpress' then 'sucursal'
    when 'sucursal starken-turbus', 'starken-turbus', 'starken' then 'sucursal'
    when 'dhl' then 'domicilio'
    when 'muvsmart', 'chileparcels', 'motopartner' then 'domicilio'
    when 'correoschile', 'correos chile' then 'sucural'
    when 'bluexpress' then 'sucursal'
    when 'shippify' then 'docmicilio'
    else
      ['sucursal'].include?(package['destiny'].try(:downcase)) ? 'sucursal' : 'domicilio'
    end
  end

  def self.validate_shipment(package)
    carrier = Couriers::CourierGeneric.new(name: package['courier_for_client'].try(:downcase),
                                           type_of_destiny: package['destiny'],
                                           payable: package['is_payable'],
                                           reference: package['reference'],
                                           commune_id: package['address_attributes']['commune_id']).instance
    carrier.valid_shipment
  rescue StandardError => _e
    false
  end

  def self.courier_branch_office_destiny?(package)
    return false if package[:courier_branch_office_id].try(:to_i).try(:zero?)

    ['chilexpress', 'starken-turbus', 'correoschile'].include?(package['destiny'].downcase)
  end

  def self.change_courier_destiny(courier_branch_offices, package)
    courier_branch_office = find_courier_destiny(courier_branch_offices, package)
    courier_branch_office['id']
  end

  def self.find_courier_destiny(courier_branch_offices, package)
    courier_branch_office = courier_branch_offices.find do |cbo|
      courier = cbo['courier_bo_id'].split('-')[0].strip
      courier.downcase.include?(package['courier_for_client'].downcase) && cbo['commune_id'] == package['address_attributes']['commune_id'].to_i
    end
    message = "No se pudo procesar la órden #{package[:reference]}: "\
              'No se encontro sucursal para el courier ingresado'
    raise message unless courier_branch_office.present?

    courier_branch_office
  end

  def self.packages_to_pickup(packages)
    packages.reject { |package| package.inventory_activity.present? || package.is_returned }
  end

  def self.pickup_email(data, account, branch_office, has_test_packages, sandbox, alert)
    return if branch_office.company.fulfillment? || has_test_packages || sandbox
    return unless alert

    OrderMailer.warn_about_hero(data, account, branch_office).deliver
  end

  def self.select_availables_to_get_price(packages)
    packages.reject(&:is_payable)
            .reject { |package| package.courier_for_client.present? && package.shipping_price.try(:to_i).try(:positive?) }
  end

  def self.select_availables_to_get_tracking(packages)
    packages.select do |package|
      next unless package.courier_for_client.present?
      # production validation | unnecessary because all shipments created doesn't have tracking
      next if package.tracking_number.present?
      next if ['retiro cliente', 'despacho retail'].include?(package.destiny.downcase)
      next if package.is_payable && package.destiny.downcase == 'domicilio' && package.courier_for_client.downcase == 'chilexpress'

      package
    end
  end

  def self.insurance(package)
    insurance = insurance_attributes(package)
    { ticket_number: insurance[:ticket_number],
      ticket_amount: insurance[:ticket_amount] || insurance[:amount],
      detail: insurance[:detail],
      extra: insurance[:extra] || insurance[:extra_insurance] }
  rescue => e
    { ticket_number: '',
      ticket_amount: 0,
      detail: '',
      extra: false }
  end

  def self.insurance_attributes(package)
    package[:insurance_attributes] || package[:purchase]
  end

  def self.apply_delayed_rules(package)
    return false unless exists_delivery_date?(package)

    deadline_courier_expired(package)
  end

  def self.exists_delivery_date?(package)
    delivery_date_calculated =
      if package.operation_date && package.delivery_time
        package.operation_date + package.delivery_time.to_i.days
      end
    @delivery_date = package.prediction.try(:delivery_date) || delivery_date_calculated
    @delivery_date.present?
  end

  def self.deadline_courier_expired(package)
    CourierService.deadline_courier_expired(package, @delivery_date)
  end
end
