class V::V4::CourierDestiniesController < V::ApplicationController
  def availability
    @courier_destinies = Opit.get_courier_destiny_availability(params)
    respond_with @courier_destinies
  end
end
