class SettingsController < ApplicationController
  before_action :set_setting, only: %i[edit update prices import couriers update_integrations edit_integration]
  before_action :set_service, only: %i[edit update prices import couriers]
  before_action :set_settings, only: %i[api]
  before_action :set_oauth, only: %i[oauth_bridge bootic_callback]
  before_action :set_company, only: %i[bootic_callback]
  before_action :set_products, only: %i[index]
  before_action :set_packings, only: %i[index]

  def index
    @services = Service.where(name: ['pp','fulfillment'])
    @fulfillment = current_account.entity.specific.fulfillment?
  end

  def current
    @setting = Setting.find_by(service_id: params[:service_id], company_id: current_account.entity.specific.id)
    sanitize_couriers if params[:service_id].to_i == 1
    render json: @setting, status: :ok
  end

  def my_integrations; end

  def fullit_setting
    @setting = Setting.fullit(current_account.entity.specific.id)
    render json: @setting, status: :ok
  end

  def sellers_integrated
    @sellers = current_account.entity.specific.integrations_activated
    render json: @sellers, status: :ok
  end

  def edit; end

  def update
    if @setting.service_id == 1
      @setting.update_courier_configuration(settings_params['configuration']['opit'])
      render json: @setting, status: :ok
    elsif @setting.update_columns(configuration: settings_params[:configuration])
      @setting.set_account_printer if @setting.printer_service?
      render json: @setting, status: :ok
    else
      render json: @setting, status: :error
    end
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se actualizaron los datos, favor intenta más tarde'
    render json: 'error al actualizar su configuracion', status: :error
  end

  def api
    @company = current_account.entity_specific
  end

  def webhooks
    params[:settings].map do |setting_to_set|
      setting = Setting.find(setting_to_set.first)
      setting.set_webhooks(setting_to_set.second)
    end
    redirect_to api_settings_path
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se actualizaron los datos, favor intenta más tarde'
    redirect_back(fallback_location: { action: :api })
  end

  def prices
    return @service, @setting
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se ha podido cargar la pagina, favor intenta más tarde'
  end

  def import
    @courier_prices = Setting.import(params)
    raise 'No se pudo importar la información' if @courier_prices.nil? || !Setting.save_courier_prices(@courier_prices, @setting, @service)
    flash[:info] = 'Precios Guardados'
    redirect_back(fallback_location: { action: :prices })
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se pudo importar la información'
    redirect_back(fallback_location: { action: :prices })
  end

  def couriers
    if @service.name == 'opit'
      @couriers = @setting.configuration['opit']['couriers']
      if @couriers.nil?
        render json: { error: 'Sin courier asignados' }, status: :bad_request
      else
        render json: @couriers, status: :ok
      end
    else
      render json: { error: 'No se encontraron courier asignados' }, status: :bad_request
    end
  end

  def config_couriers; end

  def config_printers; end

  def update_integrations
    if @setting.integrate_seller(integrations_params)
      render json: @setting, status: :ok
    else
      render json: { error: 'Problemas al configurar tu integración.' }, status: :bad_request
    end
  rescue => e
    render json: { error: 'No se ha podido configurar la integración, favor intentar más tarde.' }, status: :bad_request
  end

  def integrations; end

  def oauth_bridge
    redirect_to(@client.auth_code.authorize_url(redirect_uri: 'https://clientes.shipit.cl/settings/bootic_callback', scope: 'admin'))
  end

  def bootic_callback
    setting = @company.settings.find_by(service_id: 2)
    raise unless setting.integrate_seller({ authorization_token: params[:code], seller: 'bootic' })
    flash[:sucess] = 'Felicidades, Estas solo un paso de integrar tu tienda.'
    redirect_to(my_integrations_settings_path)
  rescue => e
    NotificationMailer.generic('Error al configurar bootic', "mensage: #{e.message}\n authorization_token: #{params[:code]}", current_account.entity_specific).deliver_now
    flash[:danger] = 'Error al configurar bootic, nos pondremos en contacto para resolver el problema.'
    redirect_to(my_integrations_settings_path)
  end

  private

  def set_setting
    @setting = Setting.find(params[:id] || params[:setting_id]) if params[:id] || params[:setting_id]
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se pudo obtener la información necesaria...'
    redirect_back(fallback_location: { action: :edit })
  end

  def set_service
    @service = Service.find(params[:service_id]) if params[:service_id]
  rescue
    flash[:danger] = 'No se pudo obtener la información necesaria...'
    redirect_back(fallback_location: { action: :edit })
  end

  def set_settings
    @settings = current_account.entity.actable.settings.where(service_id: [3, 4])
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se pudo obtener la información necesaria...'
    redirect_back(fallback_location: { action: :get })
  end

  def settings_params
    param = params.require(:setting).permit!
    param[:configuration] = params[:setting][:configuration].as_json
    param
  end

  def integrations_params
    params.require(:data).permit(:client_id, :client_secret, :automatic, :hour, :packing, :store_name, :show_shipit_checkout, :automatic_delivery, :seller, store_keys: [], fields: { commune: [], street: [], number: [], complement: []})
  end

  def set_oauth
    @client = OAuth2::Client.new(ENV['BOOTIC_CLIENT_ID'], ENV['BOOTIC_CLIENT_SECRET'], site: 'https://auth.bootic.net')
  end

  def set_company
    @company = current_account.entity_specific
  end

  def sanitize_couriers
    @setting.configuration['opit']['couriers'].map do |courier|
      courier.values.delete_if do |key, value|
        next unless key['from'] == 'shipit'
        key.delete('username')
        key.delete('password')
        key.delete('tcc_number')
        key.delete('company_id')
        key.delete('company_checker')
        key.delete('checking_account')
        key.delete('verification_digit')
        key.delete('cost_center')
        key.delete('code')
        key.delete('api_key')
        key.delete('base_url')
        key.delete('token_tracking')
        key.delete('token_label')
      end
    end
  end

  def set_products
    @products = current_account.current_company.products unless current_account.nil?
  end
  
  def set_packings
    @packings = current_account.current_company.packings unless current_account.nil?
  end
end
