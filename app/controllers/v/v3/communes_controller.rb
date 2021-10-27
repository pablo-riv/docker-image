class V::V3::CommunesController < V::ApplicationController

  api :GET, "/communes", "show all communes avalibles and their details"
  def index
    respond_with Commune.filter(params.slice(:recheable, :generic, :chilexpress, :starken, :with_name, :with_region_id, :code_starts_with, :starts_with, :limit, :offset))
  end

  api :GET, "/communes/:id", "show an specific commune detail"
  param :id, :number, desc: "this is the parameter to filter", required: true
  def show
    respond_with Commune.find_by(id: params[:id])
  end

  def by_name
    respond_with Commune.find_by(name: params[:name].to_s)
  end

  private

  def commune_params
    params.require(:commune).permit(Commune.allowed_attributes)
  end
end
