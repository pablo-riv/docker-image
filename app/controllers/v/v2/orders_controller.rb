class V::V2::OrdersController < V::ApplicationController
  include Packable
  before_action :set_account, only: %i[order_received order_patch]
  before_action :set_company
  before_action :set_branch_office
  before_action :set_service, only: [:create]

  api :POST, '/orders', 'Here is where you can send packages to create'
  param_group :pack, Packable
  def create
    if current_account.current_company.platform_version == 2
      oss = OrderService.invert_package_to_order(@branch_office, order_params)
      render json: { orders: oss }, status: :ok
    else
      api = OrderApi.new(email: current_account.email,
                         authentication_token: current_account.authentication_token,
                         account: current_account,
                         company: @company,
                         algorithm: @opit.algorithm,
                         packages: [order_params.to_h])
      response = api.post
      raise response['error'] unless (200..204).cover?(response.code)

      render json: { orders: response['success'], message: 'Ordenes creadas.', state: :ok }, status: :ok
    end
  rescue StandardError => e
    Rails.logger.info "#{e.message} \n #{e.backtrace.first(5).join("\n")}".red
    render json: { error: e.message }, status: :bad_request
  end

  def massive
    @orders = orders_params.map do |order|
      OrderService.invert_package_to_order(@branch_office, order)
    end
    render json: { orders: @orders }, status: :ok
  rescue StandardError => e
    Rails.logger.info "#{e.message} \n #{e.backtrace.first(5).join("\n")}".red
    render json: { error: e.message }, status: :bad_request
  end

  private

  def set_branch_office
    @branch_office = branch_office
  end

  def set_company
    @company = company
  end

  def set_service
    @fulfillment = current_account.entity_specific.services.find_by(id: 4) if current_account.has_role?(:owner)
    @opit = Setting.opit(@company.id)
  end

  def order_params
    params.require(:order).permit(Package.allowed_attributes)
  end

  def orders_params
    params.require(:orders).map do |order|
      order.permit(Package.allowed_attributes)
    end
  end
end
