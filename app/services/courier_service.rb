class CourierService
  NAMES = ['chilexpress', 'starken', 'correoschile', 'dhl', 'muvsmart', 'fulfillment delivery', 'chileparcels', 'motopartner', 'bluexpress', 'shippify'].freeze

  def self.normalize(str)
    return if str.blank?

    name = NAMES.find { |nm| nm.include?(str.try(:downcase)) }
    name.blank? ? str : name
  end

  def self.deadline_courier_expired(package, delivery_date)
    courier_object =
      case package.courier_for_client.try(:downcase)
      when 'chilexpress' then ProactiveMonitoring::ChilexpressService.new(package, delivery_date)
      when 'bluexpress' then ProactiveMonitoring::BluexpressService.new(package, delivery_date)
      when 'starken' then ProactiveMonitoring::StarkenService.new(package, delivery_date)
      when 'muvsmart' then ProactiveMonitoring::MuvsmartService.new(package, delivery_date)
      when 'motopartner' then ProactiveMonitoring::MotopartnerService.new(package, delivery_date)
      end
    return false if courier_object.nil?

    courier_for_client = package.courier_for_client.try(:camelcase)
    courier_for_client = 'MuvSmart' if courier_for_client == 'Muvsmart'
    courier_for_client = 'MotoPartner' if courier_for_client == 'Motopartner'
    courier_object.engagement_rules = Courier.find_by(name: courier_for_client)
                                             .courier_engagement_rule
    courier_object.deadline_expired
  end

  def self.base_hash_delayed_packages
    OperationalInformation::ProactiveMonitoring.compose_hash_struct
  end
end
