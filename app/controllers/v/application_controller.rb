class V::ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  acts_as_token_authentication_handler_for Account, fallback_to_devise: false
  before_action :check_authentication
  before_action :cors_preflight_check
  after_action :cors_set_access_control_headers
  before_action :add_allow_credentials_headers
  before_action :set_paper_trail_whodunnit
  include Rejectable

  respond_to :json

  def branch_office
    current_account.has_role?(:owner) ? current_account.entity_specific.default_branch_office : current_account.entity_specific
  end

  def branch_offices
    company.branch_offices
  end

  def company
    current_account.current_company
  rescue => _e
    render json: { message: 'Cliente no encontrado', state: :error }, status: :unauthorized
  end

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
      render text: '', content_type: 'application/json'
    end
  end

  def add_allow_credentials_headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods'] = 'POST, PUT, PATCH, DELETE, GET, OPTIONS'
    response.headers['Access-Control-Request-Method'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Shipit-Email, X-Shipit-Access-Token'
  end

  def check_authentication
    # MONKEY PATCH TO ENABLE API WITHOUT AUTHENTICATION
    permit_paths = %w[communes login sign_up paswords reset_password logout]
    return if permit_paths.include?(params[:controller].split('/').try(:third))
    return if params[:controller].split('/').try(:second) == 'zendesk'

    raise unless current_account.present?
  rescue => _e
    render json: { message: 'Usuario no autenticado', state: :error }, status: :unauthorized
  end
end
