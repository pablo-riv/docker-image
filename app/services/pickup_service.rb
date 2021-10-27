class PickupService
  include HTTParty
  BASE_URI = Rails.configuration.pick_and_pack_url
  KEY = 'pickups'
  # Business rules: to enable Shippify as next day courier
  COURIERS_TO_DISCRIMINATE = %w()

  def initialize(attributes)
    @attributes = attributes
  end

  def self.all
    $redis.lrange(KEY, 0, -1).map do |data|
      JSON.parse(data).with_indifferent_access
    end
  end

  def self.by_dates(start_date = (Time.now - 1.days), end_date = Time.now)
    start_date = start_date.strftime('%d-%m-%Y')
    end_date = end_date.strftime('%d-%m-%Y')
    pickups = $redis.lrange(KEY, 0, -1).map do |pickup|
      pickup if pickup[:created_at].strftime('%d-%m-%Y') >= start_date && pickup[:created_at].strftime('%d-%m-%Y') <= end_date
    end

    pickups.compact
  end

  def self.from_company(id)
    company = Company.find(id).serializable_hash(include: [:packages])
    pickups = company['packages'].map do |package|
      [package['pickup_id']] if package['created_at'].strftime('%d-%m-%Y') == Time.now.beginning_of_day.strftime('%d-%m-%Y')
    end.uniq.compact

    company.merge(pickups: pickups)
  end

  def self.find(id)
    pickup = $redis.lrange(KEY, 0, -1).map do |data|
      pickup = JSON.parse(data).with_indifferent_access
      pickup if pickup[:id] == id
    end.first
  end

  def self.update(pickup)
    $redis.lrange(KEY, 0, -1).each do |data|
      data = JSON.parse(data).with_indifferent_access
      data = pickup if pickup[:id] == data[:id]
    end
  end

  def self.create(pickup)
    $redis.lpush(KEY, pickup)
    $redis.ltrim(KEY, 0, -1)
  end

  def self.archive_items(params)
    request = HTTParty.post("#{BASE_URI}items/massive_archive_by_package_id", { body: params, verify: false })
    request.parsed_response
  end

  def update_shipment_dispatch
    raise 'No es posible reagendar los envíos seleccionados' unless shipments.present?

    shipments.each do |shipment|
      reschedule_object = { updates: shipment.reschedule['updates'] + 1,
                            user_id: @attributes[:account].id,
                            updated_at: DateTime.current,
                            old_operation_date: shipment.operation_date }
      shipment.update_columns(operation_date: pickup_date, processed_by_beetrack: false, deleted_in_beetrack: false, status: 0, sub_status: 'in_preparation', reschedule: reschedule_object)
    end
  end

  def add_shipments_to_pickup
    company = branch_office.company
    return if company.fulfillment?

    pickups = generate_pickups&.compact
    pickups.each(&:generate_manifest)
  end

  private

  def generate_pickups
    shipments_by_date = shipments.group_by(&:operation_date)
    shipments_by_date.map do |date, shipment_group|
      next if date.blank?

      local_date = (pickup_date || date).to_date.to_s
      pickup = find_pickup(local_date) || generate_pickup(local_date)
      next if pickup.blank?

      Rails.logger.info("pickups.packages count: #{pickup.packages.count} << shipment_group count: #{shipment_group.size}".cyan.swap)
      Rails.logger.info(branch_office.name.green.swap)
      Rails.logger.info("pickup_id: #{pickup.id}\nshipment_ids: #{shipment_group.pluck(:id, :branch_office_id)}".yellow.swap)
      PackagesPickup.transaction do
        pickup.packages << shipment_group
      end
      pickup.update_uuids
      pickup
    end
  end

  def find_pickup(local_date)
    Pickup.find_by("branch_office_id = ? AND schedule ->> 'date' = ? AND provider = ?", branch_office.id, local_date, provider)
  end

  def generate_pickup(local_date)
    branch_address = branch_office.default_address
    address = { place: "#{branch_address.street} #{branch_address.number}, #{branch_address.commune.name.titleize}",
                coords: { lat: branch_address.coords[:latitude],
                          lng: branch_address.coords[:longitude] } }
    pickup = nil
    Pickup.transaction do
      pickup =
        Pickup.create(status: 0,
                      provider: provider,
                      schedule: { date: local_date, range_time: range_time, active: true },
                      address: address,
                      branch_office_id: branch_office.id)
    end
    pickup
  rescue StandardError => e
    error_message = "PickupService#generate_pickup - Error: #{e.message}\n"\
                    "BUGTRACE: #{e.backtrace.first(3).join("\n")}"
    Rails.logger.info(error_message.red)
    find_pickup(local_date)
  end

  def pickup_date
    @attributes[:date]
  end

  def provider
    @attributes[:provider] || 'shipit'
  end

  def shipments
    @attributes[:shipments]
  end

  def branch_office
    @attributes[:branch_office]
  end

  def shipments_data_manifest(pickup_shipments)
    pickup_shipments.map do |shipment|
      {
        id: shipment.id,
        reference: shipment.reference,
        tracking_number: shipment.tracking_number,
        items_count: shipment.items_count,
        full_name: shipment.full_name,
        commune: shipment.address&.commune&.name
      }
    end
  end
end
