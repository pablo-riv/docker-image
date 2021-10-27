class FulfillmentService
  include HTTParty
  BASE_URI = Rails.configuration.fulfillment_endpoint

  def self.create_package(package, company_id)
    response = HTTParty.post("#{BASE_URI}inventories/#{company_id}/create_package", { body: { package: package[:packages] }, verify: false })
    response.parsed_response.blank? ? true : response.parsed_response
  end

  def self.get_price(package)
    response = HTTParty.post("#{BASE_URI}tool/measures", { package: package, verify: false })
    JSON.parse(response.body)
  end

  def self.by_client(company_id)
    response = HTTParty.get("#{BASE_URI}skus/#{company_id}/by_client", { verify: false })
    response.parsed_response.blank? ? [] : response.parsed_response
  end

  def self.skus_by_client(params)
    response = HTTParty.get("#{BASE_URI}skus/", { query: { company_id: params[:company_id],
                                                           availables: params[:availables],
                                                           value: params[:value],
                                                           query: params[:query],
                                                           page: params[:page],
                                                           per: params[:per] },
                                                 verify: false })
    return [] if (400..500).cover?(response.code)

    HashWithIndifferentAccess.new(response)
  end

  def self.inventory_activities_by(company_id, type, page = 1, per = 50)
    response = HTTParty.get("#{BASE_URI}inventories/#{company_id}/movements", { query: { inventory_activity_type_id: type, page: page, amount: per }, verify: false })
    response.parsed_response.blank? ? [] : response.parsed_response
  end

  def self.movements(company_id, type, page = 1, per = 50)
    response = HTTParty.get("#{BASE_URI}inventories/#{company_id}/movements_paginated", { query: { inventory_activity_type_id: type, page: page, per: per }, verify: false })
    response.parsed_response.blank? ? [] : response.parsed_response
  end

  def self.inventory(id)
    response = HTTParty.get("#{BASE_URI}inventories/#{id}", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.sku(id)
    response = HTTParty.get("#{BASE_URI}skus/#{id}", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.sku_by_name(name)
    response = HTTParty.get("#{BASE_URI}skus/by_name/#{name}", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.sku_by_client_and_name(company_id, sku_name = nil)
    response = HTTParty.get("#{BASE_URI}skus/#{company_id}/by_name", { query: { name: sku_name }, verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.sku_by_client(company_id, sku_id)
    response = HTTParty.get("#{BASE_URI}skus/#{sku_id}/company/#{company_id}", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.update_min_stock(sku)
    response = HTTParty.put("#{BASE_URI}skus/#{sku['id']}", { body: { sku: { id: sku['id'], min_amount: sku['min_amount'] }, from: 'client' }, verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.order_skus(package_id)
    response = HTTParty.get("#{BASE_URI}inventories/orders/#{package_id}", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.warehouses
    response = HTTParty.get("#{BASE_URI}warehouses", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.cancel_packages(args)
    response = HTTParty.post("#{BASE_URI}inventories/cancel_packages", { body: { package_ids: args }, verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.new_series_out(args)
    response = HTTParty.post("#{BASE_URI}series", { body: args, verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.series_by_package(args)
    response = HTTParty.get("#{BASE_URI}series/search_by_package/#{args}", { verify: false })
    response.parsed_response.blank? ? {} : response.parsed_response
  end

  def self.compraqui_package?(params)
    # production code
    true # Package.find_by(id: params['listaLpnDestino'].first['ordendesalida']).try(:company).try(:id) == 1678
  end
end
