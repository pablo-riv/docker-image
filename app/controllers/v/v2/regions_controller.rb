class V::V2::RegionsController < V::ApplicationController

  api :GET, "/regions", "show all regions avalibles and their details"
  def index
    respond_with Region.filter(params.slice(:with_name, :starts_with, :limit, :offset ))
  end

  api :GET, "/regions/:id", "show an specific region detail"
  param :id, :number, desc: "this is the parameter to filter", required: true
  def show
    respond_with Region.find(params[:id])
  end
end
