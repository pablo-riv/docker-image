require 'rails_helper'

RSpec.describe ShipmentsController, type: :controller do
  context 'return price for package' do
    before_each do
      @package = FactoryBot.build(:package)
    end

    describe "POST #price" do
      it 'return Hash with values'
      it 'retun empty Hash if data is not found'
    end

    describe "POST #prices" do
      it 'return Array of hash with values'
      it 'retun empty Array if data is not found'
    end
  end
end
