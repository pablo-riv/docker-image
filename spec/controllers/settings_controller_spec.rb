require 'rails_helper'
require 'factory'

RSpec.describe SettingsController, type: :controller do
  describe 'GET #index' do
    before do
      get :index
    end

    it 'Returns successful response' do
      expect(response).to be_successful
    end

    it 'View co' do
      expect(response).to be_successful
    end
  end
end