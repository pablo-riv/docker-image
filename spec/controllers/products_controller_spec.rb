require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  
  describe "GET #NewProduct" do
    login_account

    it 'Display new product form' do
      get :new
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end
  end

  describe "GET #ProductDetail" do
    login_account

    it 'Returns a successful response' do
      @product = Product.create(FactoryBot.build(:product).attributes)
      get :show, params: { id: @product.id }
      expect(response).to be_successful
    end
  end

  describe "GET #EditProduct" do
    login_account

    it 'Returns a successful response' do
      @product = Product.create(FactoryBot.build(:product).attributes)
      get :edit, params: { id: @product.id }
      expect(response).to be_successful
    end
  end
end
