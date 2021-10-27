module VtexConnection
  extend ActiveSupport::Concern
  included do
    def download_vtex(setting)
      vtex = VtexService.new(@client_id, @client_secret, @store_name)
      response = vtex.orders(setting.company_id, self)
      return unless response.present?

      response
    end

    def update_vtex_order(order, package)
      vtex = VtexService.new(@client_id, @client_secret, @store_name)
      vtex.update_vtex_order(order, package)
    end
  end
end
