class V::V4::IntegrationsController < V::ApplicationController
  before_action :set_company
  before_action :set_integration, only: %i[show setting index]
  before_action :set_sellers, only: %i[index]
  before_action :set_webhook, only: %i[webhook configuration]
  before_action :set_seller, only: %i[show]

  def index
    respond_with(@sellers)
  end

  def show
    render json: @seller, status: :ok
  end

  def setting
    Setting.transaction do
      @integration.configuration['fullit']['sellers'].map do |seller|
        next unless seller[seller_params[:name]].present?

        seller[seller_params[:name]]['client_id'] = seller_params[:username]
        seller[seller_params[:name]]['client_secret'] = seller_params[:password]
        seller[seller_params[:name]]['store_name'] = seller_params[:store_name]
        seller[seller_params[:name]]['show_shipit_checkout'] = seller_params[:show_shipit_checkout] || true
        seller[seller_params[:name]]['automatic_delivery'] = seller_params[:automatic_delivery] || false
      end
      raise unless @integration.update_columns(configuration: @integration.configuration)

      respond_with(@integration)
    end
  rescue => e
    render_rescue(e)
  end

  def webhook
    Setting.transaction do
      @webhook.configuration['pp']['webhook']['package'] = webhook_params[:package]
      raise unless @webhook.update_columns(configuration: @webhook.configuration)

      respond_with(@webhook)
    end
  rescue => e
    render_rescue(e)
  end

  def configuration
    respond_with(@webhook)
  end

  private

  def set_company
    @company = company
  end

  def set_sellers
    @sellers = @integration.configuration['fullit']['sellers'].reject do |seller|
      ['bsale', 'dafiti', 'opencart', 'vtex', 'drupal', 'magento_one', 'magento_two'].include?(seller.keys[0])
    end
  end

  def set_integration
    @integration = Setting.fullit(company.id)
    raise 'Sin configuracion disponible' unless @integration.present?
  rescue => e
    render_rescue(e)
  end

  def set_webhook
    @webhook = Setting.pp(company.id)
    raise 'Sin configuracion disponible' unless @webhook.present?
  rescue => e
    render_rescue(e)
  end

  def set_seller
    @seller = @integration.seller_configuration(params[:name])
    raise 'Integración no encontrada.' unless @seller.present?
  rescue => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def seller_params
    params.require(:seller).permit(:name, :username, :password, :store_name, :show_shipit_checkout, :automatic_delivery)
  end

  def webhook_params
    params.require(:webhook).permit(package: [:url, options: [sign_body: [:required, :token], authorization: [:required, :kind, :token]]])
  end
end
