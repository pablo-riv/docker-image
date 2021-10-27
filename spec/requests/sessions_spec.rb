require 'rails_helper'
require 'rails_helper'

RSpec.describe "Sessions", type: :request do

  describe "signs account in and out" do
    before do
      @account ||= Account.first || FactoryBot.create(:account)
    end
    
    it 'Sign in' do
      sign_in @account
      get root_path
      expect(controller.current_account).to eq(@account)
    end

    it 'Sign out' do
      sign_out @account
      get new_account_session_path
      expect(controller.current_account).to be_nil
    end
  end
end