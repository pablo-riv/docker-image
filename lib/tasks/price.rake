namespace :price do
  desc 'Re-generate prices by date. Receive: dd-mm-yyy'
  task :re_generate, [:date] => :environment do |args|
    date = Time.parse("#{} 14:06:00")
    year = date.strftime('%Y')
    month = date.strftime('%m')
    date = date.to_s

    after_10_feb = Package.by_date(year,month).where('created_at >= ?',date);
    equals_couriers = after_10_feb.where("(courier_for_client = 'chilexpress' AND courier_for_entity = 'chilexpress') OR (courier_for_client = 'starken' AND courier_for_entity = 'starken')");
    ec_check_couriers_with_chilexpress = equals_couriers.where(courier_for_client: 'chilexpress').where(courier_for_entity: 'chilexpress')
    ec_check_couriers_with_starken = equals_couriers.where(courier_for_client: 'starken').where(courier_for_entity: 'starken')
    ec_to_branch_office = equals_couriers.where("destiny != 'Domicilio'")
    ec_to_home = equals_couriers.where(destiny: 'Domicilio')

    not_equals_couriers = after_10_feb.where("courier_for_client != courier_for_entity OR (courier_for_client IS NULL AND courier_for_entity IS NOT NULL) OR (courier_for_entity IS NULL AND courier_for_client IS NOT NULL)")

    cd_to_branch_office = not_equals_couriers.where("destiny != 'Domicilio'")
    cd_to_home = not_equals_couriers.where(destiny: "Domicilio'")

    equals_are_payables =  equals_couriers.where(is_payable: true)
    not_equals_are_payables =  not_equals_couriers.where(is_payable: true)

    ec_to_branch_office.each do |package|
      package.update_columns(courier_for_client: nil, courier_for_entity: nil, is_bug: true)
      package.set_price
    end

    ec_to_home.each do |package|
      package.update_columns(is_bug: true)
      package.set_price
    end

    cd_to_branch_office.each do |package|
      package.update_columns(courier_for_client: nil, courier_for_entity: nil, is_bug: true)
      package.set_price
    end

    cd_to_home.each do |package|
      package.update_columns(courier_for_client: nil, courier_for_entity: nil, is_bug: true)
      package.set_price
    end

    equals_are_payables.each do |package|
      package.update_columns(shipping_price: 0, is_bug: true)
    end

    not_equals_are_payables.each do |package|
      package.update_columns(shipping_price: 0, is_bug: true)
    end
  end

  desc 'Import custom price for patagonia packages'
  task custom: :environment do
    CSV.foreach("#{Rails.root}/lib/data/kit11.csv", headers: true) do |row|
      price = row.to_hash.with_indifferent_access
      package = Package.find_by(id: price[:id])
      next unless package.present?
      package.update_columns(shipping_price: price[:price])

      prices = Price::Shipment.new(
        subscription: package.company_current_subscription,
        courier_selected: package.courier_selected,
        total_price: package.total_price,
        shipping_price: package.shipping_price,
        shipping_cost: package.shipping_cost,
        insurance_price: package.insurance_price,
        material_extra: package.material_extra,
        is_paid_shipit: package.is_paid_shipit,
        is_payable: package.is_payable,
        packing: package.packing,
        height: package.height,
        width: package.width,
        length: package.length
      ).calculate_prices

      package.update_columns(
        total_is_payable: prices[:total_is_payable],
        material_extra: prices[:material_extra],
        shipping_price: prices[:shipping_price],
        shipping_cost: prices[:shipping_cost],
        total_price: prices[:total_price]
      )
    end
  end

  desc 'Packages without spreadsheet version cause algorithm days is too long'
  task errors_algorithm: :environment do
    CSV.foreach("#{Rails.root}/lib/data/remanente_cobranza.csv", headers: true) do |row|
      price = row.to_hash.with_indifferent_access
      package = Package.find_by(id: price[:id])
      next unless package.present?

      package_params = { length: package.length,
                         width: package.width,
                         height: package.height,
                         weight: package.weight,
                         to_commune_id: package.commune.id,
                         is_payable: package.is_payable,
                         destiny: 'Domicilio',
                         courier_selected: true,
                         courier_for_client: package.courier_for_client }.with_indifferent_access

      ship = Opit.new(package_params, false)
      company = package.company
      current_account = company.default_account
      data = ship.prices(current_account).with_indifferent_access

      prices = Price::Shipment.new(
        subscription: package.company_current_subscription,
        courier_selected: package.courier_selected,
        total_price: package.total_price,
        shipping_price: data[:lower][:price],
        shipping_cost: data[:lower][:cost],
        insurance_price: package.insurance_price,
        material_extra: package.material_extra,
        is_paid_shipit: package.is_paid_shipit,
        is_payable: package.is_payable,
        packing: package.packing,
        height: package.height,
        width: package.width,
        length: package.length
      ).calculate_prices


        { total_price: package.total_price,
          shipping_price: data[:lower][:price],
          shipping_cost: data[:lower][:cost],
          insurance_price: package.insurance_price,
          material_extra: package.material_extra,
          is_paid_shipit: package.is_paid_shipit,
          is_payable: package.is_payable,
          packing: package.packing,
          height: package.height,
          width: package.width,
          length: package.length }

      package.update_columns(volume_price: data[:volumetric_weight].try(:to_f),
                             spreadsheet_versions: data[:spreadsheet_versions],
                             spreadsheet_versions_destinations: data[:spreadsheet_versions_destinations],
                             total_is_payable: prices[:total_is_payable],
                             material_extra: prices[:material_extra],
                             shipping_price: prices[:shipping_price],
                             shipping_cost: prices[:shipping_cost],
                             total_price: prices[:total_price])
    end
  end
end
