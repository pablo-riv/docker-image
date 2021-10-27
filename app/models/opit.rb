class Opit
  include HTTParty
  base_uri Rails.configuration.opit_endpoint

  def self.generate_avery(packages, setting, download, version = 'v2')
    this = new()
    case version
    when 'v1' then this.generate_avery_v1(packages)
    when 'v2' then
      this.generate_avery_v2(packages, setting, download)
    end
  end

  def self.get_status(shipment)
    this = new()
    this.get_status(id: shipment.id,
                    courier_for_client: shipment.courier_for_client,
                    tracking_number: shipment.tracking_number)
  end

  def initialize(package = nil, is_v1 = true)
    @headers = { 'Accept' => 'application/vnd.opit-v2' }

    if is_v1
      @package = package.serialize_data!.to_json unless package.blank?
    else
      @package = package
    end
  end

  def shipment_cost
    self.class.post('/api/shipments/cost', { headers: @headers, body: { package: @package }, verify: false })
  end

  def shipment_price
    self.class.post('/api/shipments/price', { headers: @headers, body: { package: @package }, verify: false })
  end

  def shipment_prices
    self.class.post('/api/shipments/prices', { headers: @headers, body: { package: @package }, verify: false })
  end

  def shipment_costs
    self.class.post('/api/shipments/costs', { headers: @headers, body: { package: @package }, verify: false })
  end

  def remove_shippify_tracking
    self.class.get('/api/trackings/shippify_delete', query: { package_id: @package.id, number: @package.tracking_number }, headers: { 'Accept' => 'application/vnd.opit-v1' })
  end

  def setup_request(current_account)
    @prices_endpoint = '/api/prices'
    @headers = { 'Accept' => 'application/vnd.opit-v1' }
  end

  def default_origin_commune
    Commune.find_by(name: 'LAS CONDES').try(:id)
  end

  def prices(current_account, origin = default_origin_commune)
    @commune_to_id = @package['to_commune_id'] || @package['commune_id'] || @package['commune_to_id']
    couriers_avalables_by_coverage = Setting.get_shipment_couriers_v3(current_account, origin, @commune_to_id)
    @couriers_availables_from = couriers_avalables_by_coverage[:from]
    @couriers_availables_to = couriers_avalables_by_coverage[:to]
    setup_request(current_account)
    self.class.post(@prices_endpoint, { headers: @headers, body: prices_payload(current_account), verify: false })
  end

  def prices_payload(current_account)
    body = {
      couriers_availables_from: @couriers_availables_from,
      couriers_availables_to: @couriers_availables_to,
      length: @package['length'],
      width: @package['width'],
      height: @package['height'],
      weight: @package['weight'].to_f,
      is_payable: @package['is_payable'] || false,
      destiny: @package['destiny'].try(:downcase) || 'domicilio',
      type_of_destiny: @package['destiny'].try(:downcase) || 'domicilio',
      commune_id: @commune_to_id
    }
  end

  def shipment_costs_v2(current_account)
    @commune_from_id = @package['commune_from_id'] || default_origin_commune
    @commune_to_id = @package['to_commune_id'] || @package['commune_id'] || @package['commune_to_id']
    couriers_avalables_by_coverage = Setting.get_shipment_couriers_v3(current_account, @commune_from_id, @commune_to_id)
    @couriers_availables_from = couriers_avalables_by_coverage[:from]
    @couriers_availables_to = couriers_avalables_by_coverage[:to]
    setup_request(current_account)
    self.class.post(@prices_endpoint, { headers: @headers, body: shipment_cost_payload, verify: false })
  end

  def shipment_cost_payload
    {
      couriers_availables_from: @couriers_availables_from,
      couriers_availables_to: @couriers_availables_to,
      length: @package['length'],
      width: @package['width'],
      height: @package['height'],
      weight: @package['weight'].to_f,
      is_payable: @package['is_payable'] || false,
      destiny: @package['destiny'] || 'domicilio',
      algorithm: (!@package['algorithm'].blank?) ? @package['algorithm'] : 1,
      algorithm_days: (!@package['algorithm_days'].blank?) ? @package['algorithm_days'] : "",
      courier_for_client: @package['courier_selected'] || false ? @package['courier_for_client'] : '',
      courier_selected: @package['courier_selected'] || false,
      commune_id: @commune_to_id
    }
  end

  def generate_avery_v1(packages)
    response = self.class.post('/api/labels', { headers: { 'Accept' => 'application/vnd.opit-v1' }, body: { packages: packages.map(&:serialize_data!) }, verify: false })
    raise if response['state'] == 'error'
    response['link']
  end

  def generate_avery_v2(packages, setting, download)
    response = self.class.post('/api/labels', { headers: @headers, body: { packages: packages.to_json, setting: setting }, verify: false })
    raise if response['state'] == 'error'

    download.update_attributes(status: :success, downloaded: true, link: response['link'])
    Package.where(id: packages.pluck(:id)).update_all(label_printed: true, printed_date: Date.current)
  end

  def couriers_branch_offices(meth = 'index', filter = '', attr = 'courier_name')
    response =
      case meth.downcase
      when 'index' then self.class.get("/api/couriers_branch_offices")
      when 'show' then self.class.get("/api/couriers_branch_offices/#{filter}")
      when 'filter_by' then self.class.get("/api/couriers_branch_offices/filter_by/", query: { filter: filter, method: attr })
      else
        self.class.get("/api/couriers_branch_offices?method=#{meth.downcase}&filter=#{filter}")
      end
    response.is_a?(Array) ? { couriers_branch_offices: response }.with_indifferent_access : response
  end

  def self.get_courier_destiny_availability(params)
    response = Opit.get("/api/courier_destinies/by_availability", { query: params })
    response.is_a?(Array) ? { courier_destiny_availability: response } : response
  end

  def generate_tracking(package)
    response = self.class.post('/api/trackings', { body: package, headers: { 'Accept' => 'application/vnd.opit-v1' }, verify: false })
    Rails.logger.info { "ERROR TO GET TRACKING: #{response['error']}".red.swap }
    raise(response['error']) if response['error'].present?

    response
  end

  def get_status(package)
    response = self.class.post('/api/statuses', { headers: @headers, body: { package: package.to_json }, verify: false })
    return response.with_indifferent_access if (200..204).cover?(response.code)

    'Error al obtener el estado'
  rescue => e
    'Error al obtener el estado'
  end
end
