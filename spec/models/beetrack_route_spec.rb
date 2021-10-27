require 'rails_helper'

RSpec.describe BeetrackRoute, type: :model do
  it "Should not create a Route without all required information" do
    beetrack_route = BeetrackRoute.new
    expect(beetrack_route.save).to be false
  end

  it "Should not create a Route without the hero" do
    beetrack_route = BeetrackRoute.new({date: Date.today, route_id: 1})
    expect(beetrack_route.save).to be false
  end

  it "Should not create a Route without the route_id" do
    beetrack_route = BeetrackRoute.new({date: Date.today, hero_id: 1})
    expect(beetrack_route.save).to be false
  end

  it "Should not create a Route without the date" do
    beetrack_route = BeetrackRoute.new({route_id: 1, hero_id: 1})
    expect(beetrack_route.save).to be false
  end


  it "Should create a Route with all information" do
    beetrack_route = BeetrackRoute.new({route_id: 1, hero_id: 1, date: Date.today})
    expect(beetrack_route.save).to be true
  end
end
