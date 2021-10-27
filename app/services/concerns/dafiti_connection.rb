module DafitiConnection
  extend ActiveSupport::Concern
  included do
    def download_dafiti(setting)
      dafiti = DafitiService.new(@client_id, @client_secret)
      response = dafiti.orders
      return if response.blank?
      response['Order'].is_a?(Array) ? response['Order'].each { |order| order_to_hash(order, setting.company_id, dafiti) } : order_to_hash(response['Order'], setting.company_id, dafiti)
    end

    def dafiti_single_order(order_id, company_id)
      dafiti = DafitiService.new(@client_id, @client_secret)
      response = dafiti.order(order_id)
      return if response.blank?
      order_to_hash(response, company_id, dafiti)
    end

    def dafiti_create_webhook(params)
      dafiti = DafitiService.new(params[:client_id], params[:client_secret])
      url = {
        'email': params[:setting].company.accounts.first.email,
        'token': params[:setting].company.accounts.first.authentication_token
      }
      url = CGI.unescape(url.to_h.to_query)
      query_params = {
        'Webhook': {
          'CallbackUrl': "http://api.shipit.cl/v/orders/order_received?#{url}",
          'Events': ['onOrderCreated']
        }
      }
      query_params = query_params.to_xml(root: 'Request', skip_types: true)
      config = params[:setting].configuration
      response = dafiti.create_webhook(query_params)
      config['fullit']['sellers'][0]['dafiti']['dafiti_webhook'] = response['Webhook']['WebhookId'] unless response.include?('ErrorResponse')
      params[:setting].update_columns(configuration: config)
    end

    def dafiti_delete_webhook(webhook_id, client_id, client_secret, setting)
      params = { 'Webhook': webhook_id }.to_xml(root: 'Request', skip_types: true)
      DafitiService.new(client_id, client_secret).delete_webhook(params)
      config = setting.configuration
      config['fullit']['sellers'][1]['dafiti_webhook'] = ''
      setting.update_columns(configuration: config)
    end

    def update_dafiti_order(order, package)
      current_statuses = { 'pending': 0, 'to_marketplace': 1, 'in_preparation': 2, 'ready_to_ship': 2, 'in_route': 3, 'shipped': 3, 'delivered': 4, 'failed': 5, 'returned': 5 }
      dafiti = DafitiService.new(@client_id, @client_secret)
      items_ids = order.item_ids.split(';').map { |id| id.delete(' ', '').try(:to_i) }
      previous_state = order.seller_order_status
      raise "package #{package.id} sin courier_for_client seteado...".red if package.courier_for_client.blank?
      shipment_provider = case package.courier_for_client.downcase
                          when 'chilexpress' then 'ChileExpress'
                          when 'starken' then 'Turbus'
                          when 'correoschile' then 'Correos'
                          end
      params = { status: package.status, items: items_ids, tracking: package.tracking_number, courier: shipment_provider }
      if package.tracking_number.nil?
        puts "Setting up order status to: #{package.status.to_s.yellow}"
        params[:status] = 'to_marketplace'
        change_status(params, dafiti, order)
      else
        for i in (current_statuses[previous_state.to_sym] + 1)..current_statuses[package.status.to_sym]
          puts "Setting up order status to: #{current_statuses.key(i).to_s.yellow}"
          params[:status] = current_statuses.key(i).to_s
          change_status(params, dafiti, order)
        end
      end
    end

    def change_status(params, dafiti, order)
      response = ''
      if params[:status] == 'to_marketplace' || params[:status] == 'in_preparation'
        response = dafiti.item_status(params[:status], nil, params[:items], params[:tracking], params[:courier].capitalize)
      else
        params[:items].map do |it|
          response = dafiti.item_status(params[:status], it, nil, params[:tracking], params[:courier].capitalize)
        end
      end
      puts response.to_s.cyan
      order.dafiti_order_update_status(params[:tracking], params[:status]) unless response.include?('ErrorResponse')
      previous_log = order['status_log'].blank? ? [] : order['status_log']
      order.update_attributes(status_log: [{ message: response, time: Time.current }] + previous_log)
    end

    def order_to_hash(order, company_id, dafiti)
      new_order_hash = hash_format(order)
      order_items = dafiti.order_items(new_order_hash[:order_id])['OrderItems']
      new_order_hash.merge!(items: hash_format(order_items),
                            company_id: company_id,
                            seller: 'dafiti')
      find_or_create_order(new_order_hash)
    end
  end
end
