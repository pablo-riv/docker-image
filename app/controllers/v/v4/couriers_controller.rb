class V::V4::CouriersController < V::ApplicationController
  before_action :set_company
  before_action :set_opit, only: %i[update algorithm update_algorithm]
  before_action :set_couriers, only: %i[index]
  before_action :set_courier, only: %i[show branch_offices]
  before_action :set_courier_branch_offices, only: %i[branch_offices]

  def index
    respond_with(@couriers)
  end

  def show
    respond_with(@courier)
  end

  def branch_offices
    respond_with(@courier, @courier_branch_offices)
  end

  def update
    raise unless @opit.update_courier(courier_params, algorith_params)

    @courier = @opit.courier(courier_params[:acronym])
    @algorithm = @opit.algorithm
    respond_with(@courier, @algorithm)
  rescue => e
    render_rescue(e)
  end

  def availables
    @couriers = Setting.opit(@company.id).couriers_availables
    raise unless @couriers.present?

    render json: { couriers: @couriers, state: :ok }, status: :ok 
  rescue => e
    render_rescue(e)
  end

  def algorithm
    @algorithm = @opit.decorate.algorithm

    respond_with(@algorithm)
  rescue => e
    render_rescue(e)
  end

  def update_algorithm
    raise unless @opit.update_algorithm(algorith_params)

    @algorithm = @opit.decorate.algorithm
    respond_with(@algorithm)
  rescue => e
    render_rescue(e)
  end

  private

  def set_courier_branch_offices
    @courier_branch_offices = Opit.new({}, false).couriers_branch_offices('filter_by', @courier.name.downcase)
  end

  def set_couriers
    @couriers = Courier.where(available_to_ship: true)
    raise 'Sin couriers disponibles' unless @couriers.present?
  rescue => e
    render_rescue(e)
  end

  def set_courier
    @courier = Courier.find_by(id: params[:id], available_to_ship: true)
    raise 'Sin couriers disponibles' unless @courier.present?
  rescue => e
    render_rescue(e)
  end

  def set_company
    @company = company
  end

  def set_opit
    @opit = Setting.opit(@company.id)
  end

  def courier_params
    params.require(:courier).permit!
  end

  def algorith_params
    params.require(:algorithm).permit(:days, :kind)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
