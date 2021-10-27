class V::V4::CommunesController < V::ApplicationController
  def index
    @communes = Commune.includes(:region)
                       .filter(params.slice(:recheable, :generic, :chilexpress, :starken, :with_name, :with_region_id, :code_starts_with, :starts_with, :limit, :offset))
                       .order(name: :asc).load
    render json: @communes.map { |c| c.serializable_hash(include: :region) }
  end

  def show
    render json: Commune.find_by(id: params[:id])
  end

  def by_name
    render json: Commune.find_by(name: params[:name].to_s.try(:upcase))
  end

  private

  def commune_params
    params.require(:commune).permit(Commune.allowed_attributes)
  end
end
