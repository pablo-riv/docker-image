class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, raise: false
  acts_as_token_authentication_handler_for Account, fallback_to_devise: false
  before_action :authenticate_account!
  before_action :validate_global_address
  after_action :set_csrf_cookie_for_ng
  before_action :masquerade_account!
  before_action :set_zendesk
  before_action :set_paper_trail_whodunnit
  include Rejectable

  helper :all

  rescue_from ActionController::RoutingError, with: :error_render_method
  rescue_from ActionView::MissingTemplate, with: :error_render_method

  def after_sign_in_path_for(account)
    validate_address(account)
  end

  def validate_address(account)
    entity = account.entity
    if entity.address.valid?
      entity.actable_type == 'Company' ? dashboard_path : headquarter_dashboard_path
    else
      invalid_address
    end
  end

  def validate_global_address
    return if current_account.nil?
    return if current_account.current_company.platform_version == 3
    return if request.env['REQUEST_PATH'] == '/setup/company'

    invalid_address unless current_account.entity.address.valid?
  end

  def invalid_address
    flash[:danger] = 'Identificamos que aún no completas todos los datos... por favor completar.'
    redirect_to(setup_company_path) && return
  end

  def user_for_paper_trail
    account_signed_in? ? current_account.id : 'Public user'  # or whatever
  end

  before_action :cors_preflight_check
  after_action :cors_set_access_control_headers
  before_action :add_allow_credentials_headers

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin']  = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token, X-Shipit-Email, X-Shipit-Access-Token'
    headers['Access-Control-Max-Age']       = '1728000'
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin']  = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token, X-Shipit-Email, X-Shipit-Access-Token'
      headers['Access-Control-Max-Age']       = '1728000'
      render text: '', content_type: 'text/plain'
    end
  end

  def add_allow_credentials_headers
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'POST, PUT, PATCH, DELETE, GET, OPTIONS'
    response.headers['Access-Control-Request-Method'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Shipit-Email, X-Shipit-Access-Token'
  end

  def set_zendesk
    @zendesk_token = Rails.configuration.zendesk_token
  end

  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  protected

  def verified_request?
    super || valid_authenticity_token?(session, request.headers['X-XSRF-TOKEN'])
  end

  private

  def error_render_method
    respond_to do |format|
      format.html { render 'public/error', layout: 'application' }
      format.json { render json: { state: :error }, status: :bad_request }
    end
  end
end
