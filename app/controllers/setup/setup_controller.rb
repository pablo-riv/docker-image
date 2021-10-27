module Setup
  class SetupController < ApplicationController
    layout 'setup'
    before_action :authenticate_account!
  end
end
