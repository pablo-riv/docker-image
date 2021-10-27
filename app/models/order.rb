class Order < ApplicationRecord
  # RELATIONS
  belongs_to :company
  has_one :package
  # TYPES
  enum service:   { pick_and_pack: 0, fulfillment: 1, labelling: 2 }, _prefix: :service
  enum state:     { draft: 0, confirmed: 1, deliver: 2, canceled: 3, archived: 4 }, _prefix: :state
  enum platform:  { form: 0, sheet: 1, api: 2, integration: 3 }, _prefix: :platform
  enum kind:      { shipit: 0, shopify: 1, prestashop: 2, woocommerce: 3, bsale: 4, jumpseller: 5, bootic: 6, opencart: 7, magento: 8, vtex: 9 }, _prefix: :kind
  # SCOPES
  default_scope { where(archive: false).where.not("orders.destiny ->> 'kind' = 'shopping_retired'") }

  def self.allowed_attributes
    [:id, :platform, :kind, :reference, :items, :sandbox, :company_id, :state, :service, :payable, :package_id,
     products: %i[sku_id name amount description warehouse_id width length height weight],
     payment: %i[type subtotal tax currency discounts total status confirmed],
     source: %i[channel ip browser language location],
     gift_card: %i[from amount total_amount],
     seller: %i[status name id reference_site],
     sizes: %i[width height length weight volumetric_weight store packing_id name],
     courier: %i[id client entity shipment_type tracking selected zpl epl pdf algorithm algorithm_days delivery_time payable without_courier],
     prices: %i[total price cost insurance tax overcharge],
     insurance: %i[max_amount ticket_amount price active extra ticket_number name store company_id insurance_id detail total_insurance],
     state_track: %i[draft confirmed deliver canceled archived],
     origin: %i[street number complement commune_id full_name email phone store origin_id name],
     destiny: %i[street number complement commune_id commune_name full_name email phone store destiny_id name courier_id courier_branch_office_id courier_branch_office_name kind fulfillment_delivery]]
  end

  def self.by_date(year: Date.current.year, month: Date.current.month)
    where("EXTRACT(YEAR FROM created_at) = ? AND EXTRACT(MONTH FROM created_at) = ?", year, month)
  end

  def self.sum_sales
    select("SUM(CAST((orders.payment ->> 'total') AS DOUBLE PRECISION)) AS sum_all")
  end

  def transform_shipment(fulfillment = false)
    transform_inventories = fulfillment_products(fulfillment)
    { reference: reference,
      full_name: destiny['full_name'],
      inventory_activity: transform_inventories['inventories'],
      email: destiny['email'],
      length: get_sizes_by_service(sizes, transform_inventories['sizes'], 'length', fulfillment),
      width: get_sizes_by_service(sizes, transform_inventories['sizes'], 'width', fulfillment),
      height: get_sizes_by_service(sizes, transform_inventories['sizes'], 'height', fulfillment),
      weight: get_sizes_by_service(sizes, transform_inventories['sizes'], 'weight', fulfillment),
      items_count: items,
      cellphone: destiny['phone'],
      is_payable: courier['payable'],
      packing: 'Sin Empaque',
      shipping_type: 'Normal',
      destiny: fulfillment_delivery(destiny, courier),
      courier_for_client: courier['client'],
      courier_selected: courier['selected'],
      delivery_time: courier['delivery_time'],
      platform: [:shipit, nil].include?(kind) ? 8 : 3,
      address_attributes: {
        commune_id: destiny['commune_id'],
        street: destiny['street'],
        number: destiny['number'],
        complement: destiny['complement']
      },
      is_sandbox: false,
      branch_office_id: company.branch_offices.ids[0],
      algorithm: courier['algorithm'].try(:to_i).try(:positive?) ? courier['algorithm'].to_i : 1,
      algorithm_days: courier['algorithm_days'].try(:to_i).try(:positive?) ? courier['algorithm_days'].to_i : 0,
      courier_branch_office_id: destiny['courier_branch_office_id'],
      service: service,
      shipping_price: prices['price'],
      shipping_cost: prices['cost'],
      total_price: prices['total'],
      total_is_payable: prices['overcharge'],
      without_courier: courier['without_courier'].try(:presence) || false,
      with_purchase_insurance: (insurance['ticket_number'].present? && insurance['ticket_amount'].present? && detail.present? && insurance['extra']),
      insurance_attributes: {
        ticket_number: insurance['ticket_number'],
        detail: detail,
        ticket_amount: insurance['ticket_amount'],
        extra: insurance['extra']
      },
      mongo_order_seller: seller['name'],
      order_id: self.id,
      seller_order_id: seller['id'] # TODO: this maybe change in the future!
    }.with_indifferent_access
  end

  def self.search_with_commune_name
    Order.joins("LEFT JOIN communes c ON (orders.destiny ->> 'commune_id')::text = c.id::text")
         .select('orders.*, c.name as commune_name')
  end

  def self.between_dates(between)
    where(created_at: between[:from]..between[:to])
  end

  def origin_valid?
    return false unless origin.present?

    %w[street number commune_id].any? { |attr| origin[attr].present? }
  end

  def destiny_valid?
    return false unless destiny.present?
    return false unless destiny['street'].present?
    return false unless destiny['number'].present?
    return false unless destiny['commune_id'].present?
    return false unless destiny['full_name'].present?
    return false if destiny['kind'] == 'courier_branch_office' && !valid_courier_branch_office?

    true
  end

  def sizes_valid?
    return false unless sizes.present?
    return false unless sizes['width'].present? && sizes['width'].to_f > 0.1
    return false unless sizes['height'].present? && sizes['height'].to_f > 0.1
    return false unless sizes['length'].present? && sizes['length'].to_f > 0.1
    return false unless sizes['weight'].present? && sizes['weight'].to_f > 0.1

    true
  end

  def courier_valid?
    return false unless courier.present?
    return false unless courier['client'].present?

    true
  end

  def prices_valid?
    return false unless prices.present?
    return false unless prices['price'].present?
    return false unless prices['cost'].present?
    return false unless prices['total'].present?

    true
  end

  def valid_courier_branch_office?
    destiny['courier_branch_office_id'].present? && courier['client'].present?
  end

  private

  def get_sizes_by_service(sizes, inventories_sizes, attribute, fulfillment)
    return sizes[attribute].to_f unless fulfillment
    return sizes[attribute].to_f unless inventories_sizes.present?
    return sizes[attribute].to_f unless inventories_sizes[attribute].to_f > 0.0

    inventories_sizes[attribute].to_f
  end

  def fulfillment_delivery(destiny, courier)
    return I18n.t("activerecord.attributes.order.destiny.kind.#{destiny['kind']}") unless courier['without_courier'].present?

    ActiveRecord::Type::Boolean.new.cast(courier['without_courier']) ? destiny['fulfillment_delivery'] : 'Domicilio'
  end

  def fulfillment_products(fulfillment)
    raise 'Cliente sin servicio fulfillment' unless products.present? && fulfillment

    data = products.map(&:to_h).delete_if { |sku| sku['id'].present? }
    # validate if needs to calculate all sizes by skus
    measures =
      if data.size > 1
        BoxifyService.new(packages: calculate_sizes(data)).calculate
      elsif data.size == 1
        size = calculate_sizes(data)
        size[0][:quantity].to_i > 1 ? BoxifyService.new(packages: size).calculate : size[0]
      end
    { inventories: { inventory_activity_orders_attributes: data }, sizes: measures }.with_indifferent_access
  rescue => e
    { inventories: nil, sizes: [] }.with_indifferent_access
  end

  def calculate_sizes(skus)
    skus.map do |sku|
      { width: sku['width'].to_f,
        length: sku['length'].to_f,
        height: sku['height'].to_f,
        weight: sku['weight'].to_f,
        quantity: sku['amount'] }
    end
  end

  def detail
    insurance['detail'] || insurance['details']
  end
end
