module ControllerMacros
  def login_account
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:account] unless @request.blank?
      account = FactoryBot.create(:account)
      sign_in account
    end
  end
end