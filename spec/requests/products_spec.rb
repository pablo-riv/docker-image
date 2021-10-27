require 'rails_helper'

RSpec.describe "Products", type: :request do
  
  context 'complete flow' do
    before do
      @account ||= Account.first || FactoryBot.create(:account)
      sign_in @account
      @product ||= nil
    end

    it 'Creates a Product' do
      @product = FactoryBot.build(:product)
      post products_path, params: { product: @product.serializable_hash }
      follow_redirect!

      expect(response).to be_successful

      @product = Product.find_by(id: response.request.params[:id])

      expect(@product).not_to be(:nil)
      expect(response).to render_template(:show)
      expect(response.body).to include(@product.name)
    end

    it 'Request details about that (or a) Product' do
      @product ||= Product.create!(FactoryBot.build(:product).attributes)
      get product_path(@product.id)

      expect(response).to be_successful
      expect(response).to render_template(:show)
      expect(response.body).to include(@product.name)
    end

    it 'Request edit product view for that (or a) Product' do
      @product ||= Product.create!(FactoryBot.build(:product).attributes)
      get edit_product_path(@product.id)

      expect(response.request.params[:id].to_s).to eq(@product.id.to_s)
      expect(response).to be_successful
      expect(response).to render_template(:edit)
      expect(response.body).to include(@product.name)
    end

    it 'Edit that (or a) Product' do
      @product ||= Product.create!(FactoryBot.build(:product).attributes)
      temp_product = FactoryBot.build(:product).serializable_hash.merge(id: @product.id)

      patch product_path(@product.id), params: { product: temp_product }
      follow_redirect!
      @product.reload

      expect(response).to be_successful
      expect(response).to render_template(:show)
      expect(response.body).to include(@product.name)
    end

    it 'Deleting that (or a) Product' do
      @product ||= Product.create!(FactoryBot.build(:product).attributes)
      delete product_path(@product.id)
      @product = Product.find_by(id: @product.id)

      expect(@product).to be(nil)

      follow_redirect!

      expect(response).to be_successful
    end
  end
end
