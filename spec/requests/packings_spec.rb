require 'rails_helper'

RSpec.describe "Packings", type: :request do
  
  context 'complete flow' do
    before do
      @account ||= Account.first || FactoryBot.create(:account)
      sign_in @account
      @packing ||= nil
    end

    it 'Creates a Packing' do
      @packing = FactoryBot.build(:packing)
      post packings_path, params: { packing: @packing.serializable_hash }
      follow_redirect!

      expect(response).to be_successful

      @packing = Packing.find_by(id: response.request.params[:id])

      expect(@packing).not_to be(:nil)
      expect(response).to render_template(:show)
      expect(response.body).to include(@packing.name)
    end

    it 'Request details about that (or a) Packing' do
      @packing ||= Packing.create!(FactoryBot.build(:packing).attributes)
      get packing_path(@packing.id)

      expect(response).to be_successful
      expect(response).to render_template(:show)
      expect(response.body).to include(@packing.name)
    end

    it 'Request edit packing view for that (or a) Packing' do
      @packing ||= Packing.create!(FactoryBot.build(:packing).attributes)
      get edit_packing_path(@packing.id)

      expect(response.request.params[:id].to_s).to eq(@packing.id.to_s)
      expect(response).to be_successful
      expect(response).to render_template(:edit)
      expect(response.body).to include(@packing.name)
    end

    it 'Edit that (or a) Packing' do
      @packing ||= Packing.create!(FactoryBot.build(:packing).attributes)
      temp_packing = FactoryBot.build(:packing).serializable_hash.merge(id: @packing.id)

      patch packing_path(@packing.id), params: { packing: temp_packing }
      follow_redirect!
      @packing.reload

      expect(response).to be_successful
      expect(response).to render_template(:show)
      expect(response.body).to include(@packing.name)
    end

    it 'Deleting that (or a) Packing' do
      @packing ||= Packing.create!(FactoryBot.build(:packing).attributes)
      delete packing_path(@packing.id)
      @packing = Packing.find_by(id: @packing.id)

      expect(@packing).to be(nil)

      follow_redirect!

      expect(response).to be_successful
    end
  end
end
