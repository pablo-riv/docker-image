class PublicController < ApplicationController
  layout :sign_in_account
  skip_before_action :authenticate_account!, raise: false, only: [:index, :deliveries]
  protect_from_forgery except: :deliveries

  def index; end

  def dashboard
    redirect_to(headquarter_dashboard_path) unless current_account.entity.actable_type == 'Company'
    if current_account.entity.address.valid?
      @last_packages = current_account.prices_by_package.order(id: :desc).limit(10)
      @chart = current_account.last_month_chart
      @states = Package.states(current_account)
      @latest_30 = Package.latest_30
      @name = current_account.entity_specific.name
      @email = current_account.email
    else
      flash[:danger] = 'Identificamos que aún no completas todos los datos... por favor completar.'
      redirect_to setup_company_path
    end
  end

  def enable_suite
    company = current_account.entity_specific
    company.update(platform_version: 3, suite_enable_count: company.suite_enable_count + 1)
    sign_out current_account
    redirect_to 'http://app.shipit.cl'
  end

  def instructions; end

  def deliveries
    delivery = DeliveryService.find_by(id: params[:id])
    if delivery.update_attributes(status: params[:status])
      Rails.logger.info { "🚴 tarea actualizada: #{delivery}".yellow }
    else
      Rails.logger.info { "🔥 tarea no actualizada: #{delivery}".yellow }
    end
  rescue => e
    Rails.logger.info { "🔥 tarea no actualizada: #{e.message}".yellow }
  end

  def fulfillment_request
    NewUserMailer.fulfillment_request(current_account, params[:request]).deliver
    render json: { message: 'Solicitud enviada, pronto nos comunicaremos.' }, status: :ok
  rescue => e
    puts e.message.to_s.red
    render json: { message: 'Solicitud no enviada, favor intentar más tarde' }, status: :bad_request
  end

  def sign_in_account
    name =
      case action_name
      when 'index' then 'public'
      when 'dashboard', 'instructions' then 'application'
      end
  end

  def catch_404
    raise ActionController::RoutingError.new(params[:path])
  end
end
