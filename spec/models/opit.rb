require 'rails_helper'

RSpec.describe Opit, type: :model do
  before(:each) do
    @package = FactoryBot.build(:package, courier_for_client: '')
    @opit = Opit.new(@package)
  end

  it 'POST #shipment_price' do
  end

  it 'POST #shipment_cost' do
  end
  it 'POST #shipment_prices' do
  end
  it 'POST #shipment_costs' do
  end
end
