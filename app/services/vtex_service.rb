class VtexService
  include HTTParty

  def initialize(client_id, client_secret, store_name)
    @headers = { 'Content-Type' => 'application/json',
                 'Accept' => 'application/json',
                 'X-VTEX-API-AppToken' => client_secret,
                 'X-VTEX-API-AppKey' => client_id }
    @url = "https://#{store_name}.vtexcommercestable.com.br/api/oms/pvt/orders"
  end

  def orders(company_id, connection, per_page = 100)
    response = HTTParty.get(@url, headers: @headers, query: { per_page: 1, page: 1 })
    return [] unless response.present?

    # calculate total pages
    pages = (response['paging']['pages'].to_f / per_page).round
    puts "TOTAL PAGES: #{pages}".green.swap
    puts "MAX PAGES: #{[1, pages].max}".green.swap
    [1, pages].max.times.each do |page|
      puts "PAGE: #{page} / #{pages}...".green.swap
      # get paged orders limit always must be 30 (vtex limit)
      order_list = HTTParty.get(@url, headers: @headers, query: { per_page: per_page, page: page })
      # iterate and add to collection
      order_list['list'].pluck('orderId').map do |id|
        # find order by list ID to get order details
        data = HTTParty.get("#{@url}/#{id}", headers: @headers)
        next if data.code == 404
        next unless ['invoiced'].include?(data['status'])

        # create or update order
        connection.find_or_create_order(mongo_template(data, company_id))
      end
    end
  end

  def order(id)
    HTTParty.get("#{@url}/#{id}", headers: @headers)
  end

  def update_vtex_order(order, package)
    raise unless order.package_tracking_number.present?

    update_status(order, package)
  rescue => e
    puts 'UPDATING PACKAGE TRACKING TO ORDER'.blue.swap
    order.update(package_tracking_number: package.tracking_number)
    update_tracking(order, package)
  end

  def update_tracking(order, package)
    HTTParty.patch("#{@url}/#{order.order_id}/invoice/#{order.invoice_number}", headers: @headers,
                                                                                body: { 'trackingNumber' => package.tracking_number,
                                                                                        'trackingUrl' => "https://seguimiento.shipit.cl/statuses?number=#{package.tracking_number}",
                                                                                        'courier' => package.courier_for_client }.to_json)
  end

  def update_status(order, package)
    vtex_order = order(order.order_id)
    order_status = vtex_order['packageAttachment']['packages'][0]['courierStatus']['data'].prepend(status(package))
    HTTParty.put("#{@url}/#{order.order_id}/invoice/#{order.invoice_number}/tracking", headers: @headers,
                                                                                       body: { 'isDelivered' => (package.status == 'delivered'),
                                                                                               'events' => order_status }.to_json)
  end

  def status(package)
    if package.status == 'in_preparation'
      city = package.branch_office.try(:address).try(:commune).try(:name)
      state = package.branch_office.try(:address).try(:commune).try(:region).try(:name)
    else
      city = package.address.try(:commune).try(:name)
      state = package.address.try(:commune).try(:region).try(:name)
    end
    { 'city': city,
      'state': state,
      'description': I18n.t("activerecord.attributes.package.statuses.#{package.status}"),
      'date': package.courier_status_updated_at }
  end

  def mongo_template(order, company_id)
    {
      seller: 'vtex',
      order_id: order['orderId'],
      seller_reference: order['sequence'],
      customer_name: order['shippingData']['address']['receiverName'],
      customer_email: order['clientProfileData']['email'],
      customer_phone: order['clientProfileData']['phone'],
      shipping_data: {
        street: order['shippingData']['address']['street'],
        number: order['shippingData']['address']['number']
      },
      shipping_data_complement: order['shippingData']['address']['complement'],
      commune: Commune.where('LOWER(name) LIKE ?', "%#{normalize_characters(order['shippingData']['address']['neighborhood']).downcase}%").first.try(:attributes),
      box_type: nil,
      sent: false,
      company_id: company_id,
      package_destiny: 'domicilio',
      package_courier_for_client: order['shippingData']['logisticsInfo'][0]['deliveryCompany'],
      package_courier_selected: false,
      package_payable: false,
      payment: order['paymentData'],
      items: order['items'],
      original_order: order,
      status: order['status'],
      vtex_created: order['creationDate'].to_date,
      invoice_number: order['packageAttachment']['packages'][0]['invoiceNumber']
    }.with_indifferent_access
  rescue => e
    Slack::Ti.new({}, {}).alert('', "CLIENTE #{company_id} NO PUEDE DESCARGAR ORDEN VTEX: #{order}\nERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
    {}
  end

  def normalize_characters(commune)
    commune.tr("ÀÁÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž","AAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
  end

  def postgres_template(_order)
    {}
  end
end
