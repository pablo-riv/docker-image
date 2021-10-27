require 'rails_helper'
require 'faker'

RSpec.describe V::V4::ShipmentsController, type: :controller do
  login_account
  before do
    @order = FactoryBot.build(:order)
  end

  describe "POST#create" do
    it "returns http success" do
      post :create, params: { order: @order.attributes }, format: :json
      expect(response).to have_http_status(:success)
      expect(response).to render_template('shipments/create')
    end

    it "fail if destiny is not present" do
      order = @order
      order.destiny = nil
      post :create, params: { order: order.attributes }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "fail if commune is not present" do
      order = @order
      order.destiny[:commune_id] = nil
      order.destiny[:commune_name] = nil
      post :create, params: { order: [order.attributes] }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "fail if sizes are not present" do
      order = @order
      order.sizes = nil
      post :create, params: { order: order.attributes }, format: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST#massive_import" do
    it "returns http success" do
      get :massive_import, params: { orders: [@order.attributes] }, format: :json
      expect(response).to render_template('shipments/massive_import')
      expect(response).to have_http_status(:success)
    end

    it "fail if destiny is not present" do
      order = @order
      order.destiny = nil
      post :massive_import, params: { order: [order.attributes] }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "fail if commune is not present" do
      order = @order
      order.destiny[:commune_id] = nil
      order.destiny[:commune_name] = nil
      post :massive_import, params: { order: [order.attributes] }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "fail if sizes are not present" do
      order = @order
      order.sizes = nil
      post :massive_import, params: { order: [order.attributes] }, format: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST#massive" do
    it "returns http success" do
      @order.save
      post :massive, params: { orders: { ids: [@order.id] } }, format: :json
      expect(response).to render_template('shipments/massive')
      expect(response).to have_http_status(:success)
    end

    it "fail if destiny is not present" do
      @order.update_attributes(state: 1, destiny: {})
      post :massive, params: { orders: { ids: [@order.id] } }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "fail if commune is not present" do
      @order.update_attributes(state: 1, destiny: {commune_id: nil, commune_name: nil})
      post :massive, params: { orders: { ids: [@order.id] } }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "fail if sizes are not present" do
      @order.update_attributes(state: 1, sizes: {})
      post :massive, params: { orders: { ids: [@order.id] } }, format: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

end
