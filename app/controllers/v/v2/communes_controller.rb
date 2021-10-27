class V::V2::CommunesController < V::ApplicationController
  api :GET, "/communes", "show all communes avalibles and their details"
  def index
    @communes = Commune.includes(:region)
                       .filter(params.slice(:recheable, :generic, :chilexpress, :starken, :with_name, :with_region_id, :code_starts_with, :starts_with, :limit, :offset))
                       .order(name: :asc).load
    render json: @communes.map { |c| c.serializable_hash(include: :region) }
  end

  api :GET, "/communes/:id", "show an specific commune detail"
  param :id, :number, desc: "this is the parameter to filter", required: true
  def show
    render json: Commune.find_by(id: params[:id])
  end

  def by_name
    render json: Commune.find_by(name: params[:name].to_s.try(:upcase))
  end

  api :GET, "/availible_commune_starken/:id", "validate indirect destiny starken"
  param :id, :number, desc: "parameter for validate indirect destiny for starken", required: true
  def availible_commune_starken
    render json: { availables: Couriers::CourierStarken.availables, state: :ok }, status: :ok
  end

  private

  def commune_params
    params.require(:commune).permit(Commune.allowed_attributes)
  end
end
