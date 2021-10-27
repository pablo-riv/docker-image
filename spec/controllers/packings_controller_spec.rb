require 'rails_helper'

RSpec.describe PackingsController, type: :controller do
  
  describe "GET #NewPacking" do
    login_account

    it 'Display new packing form' do
      get :new
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end
  end

  describe "GET #PackingDetail" do
    login_account

    it 'Returns a successful response' do
      @packing = Packing.create(FactoryBot.build(:packing).attributes)
      get :show, params: { id: @packing.id }
      expect(response).to be_successful
    end
  end

  describe "GET #EditPacking" do
    login_account

    it 'Returns a successful response' do
      @packing = Packing.create(FactoryBot.build(:packing).attributes)
      get :edit, params: { id: @packing.id }
      expect(response).to be_successful
    end
  end
end
