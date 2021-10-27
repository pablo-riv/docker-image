class OrderApi
  include HTTParty
  base_uri Rails.configuration.order_endpoint

  attr_accessor :properties, :errors
  def initialize(properties)
    @properties = properties
    @errors = []
    @headers = {
      'Accept' => 'application/vnd.orders.v1',
      'Content-Type' => 'application/json',
      'X-Shipit-Email' => properties[:email],
      'X-Shipit-Access-Token' => properties[:authentication_token]
    }
  end

  def post
    self.class.post('/orders/massive', { headers: @headers, body: { orders: orders }.to_json, verify: false })
  end

  def orders
    @properties[:packages].map do |package|
      order_template(HashWithIndifferentAccess.new(package))
    end
  end

  def company
    @properties[:company]
  end

  def algorithm
    @properties[:algorithm]
  end

  def account
    @properties[:account]
  end

  def order_template(package)
    HashWithIndifferentAccess.new(
      company_id: company.id,
      service: package[:inventory_activity].present? ? 1 : 0, # pick&pack
      kind: package[:mongo_order_seller].presence || 'shipit', # jumpseller
      platform: 3, # integration
      reference: package[:reference],
      items: package[:items_count],
      state: 1,
      seller: seller_data(package),
      products: products(package),
      payment: payment,
      prices: prices,
      courier: courier(package),
      origin: origin,
      destiny: destiny(package),
      sizes: sizes(package),
      payable: payable(package),
      insurance: insurance(package)
    )
  end

  def seller_data(package)
    { id: package[:reference],
      status: 'in_preparation',
      name: package[:mongo_order_seller].presence || 'shipit',
      reference_site: '' }
  end

  def products(package)
    return [] unless package[:inventory_activity].present?

    package[:inventory_activity][:inventory_activity_orders_attributes]
  end

  def payment
    { type: 0, subtotal: 0, currency: 0, discounts: 0, total: 0, status: 0, confirmed: 0 }
  end

  def prices
    { total: 0, price: 0, cost: 0, insurance: 0, tax: 0, overcharge: 0 }
  end

  def courier(package)
    { id: 0,
      client: validate_courier(package),
      entity: '',
      shipment_type: 'normal',
      tracking: '',
      selected: courier_selected(package),
      zpl: '',
      epl: '',
      pdf: '',
      algorithm: algorithm[:kind],
      algorithm_days: algorithm[:days],
      delivery_time: 0 }
  end

  def origin
    { street: company.address.street,
      number: company.address.number,
      complement: company.address.complement,
      commune_id: company.address.commune_id,
      full_name: account.full_name,
      email: account.email,
      phone: company.phone,
      store: false,
      origin_id: nil,
      name: 'legacy' }
  end

  def destiny(package)
    { street: package[:address_attributes][:street],
      number: package[:address_attributes][:number],
      complement: package[:address_attributes][:complement],
      commune_id: package[:address_attributes][:commune_id],
      full_name: package[:full_name],
      email: package[:email],
      phone: package[:cellphone],
      store: false,
      destiny_id: nil,
      courier_branch_office_id: package[:courier_branch_office_id],
      kind: validate_destiny(package),
      name: 'legacy' }
  end

  def sizes(package)
    { width: package[:width] || 10.0,
      height: package[:height] || 10.0,
      length: package[:length] || 10.0,
      weight: package[:weight] || 1,
      store: false,
      packing_id: nil,
      name: 'legacy' }
  end

  def validate_destiny(package)
    return 'home_delivery' unless package[:destiny].present?

    case package[:destiny].downcase
    when 'domicilio' then 'home_delivery'
    when 'sucursal', 'chilexpress', 'starken-turbus', 'correoschile' then 'courier_branch_office'
    else
      'home_delivery'
    end
  end

  def validate_courier(package)
    return '' unless package[:courier_for_client].present?

    case package[:courier_for_client].downcase
    when 'chilexpress' then 'chilexpress'
    when 'chileparcels', 'chile_parcels' then 'chileparcels'
    when 'motopartner', 'moto_partner' then 'motopartner'
    when 'starken', 'starken-turbus' then 'starken'
    when 'correoschile', 'correos_chile', 'correos_de_chile' then 'correoschile'
    when 'dhl' then 'dhl'
    when 'muvsmart' then 'muvsmart'
    when 'bluexpress' then 'bluexpress'
    when 'shippify' then 'shippify'
    else
      ''
    end
  end

  def payable(package)
    return false unless package[:is_payable].present?

    package[:is_payable]
  end

  def courier_selected(package)
    return false unless package[:courier_selected]

    package[:courier_selected] == true || package[:courier_for_client].present?
  end

  def insurance(package)
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

  def insurance_attributes(package)
    package[:insurance_attributes] || package[:purchase]
  end
end
