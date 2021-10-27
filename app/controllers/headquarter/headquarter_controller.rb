module Headquarter
  class HeadquarterController < ApplicationController
    before_action :authenticate_account!
    before_action :authenticate_account_type
    layout 'headquarter'

    def authenticate_account_type
      
      redirect_to(root_path) if current_account.has_role?(:owner)
    end
  end
end
