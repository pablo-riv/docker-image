module Setup
  class BranchOfficesController < ApplicationController
    before_action :set_branch_office, only: [:edit, :update]

    def edit
      @branch_office
    end

    def update
      if @branch_office.update(branch_office_params)
        redirect_to edit_setup_person_path(current_account.person.id)
      else
        redirect_back(fallback_location: { action: :edit })
      end
    rescue => e
      puts e.message.to_s.red
      redirect_back(fallback_location: { action: :edit })
    end

    private

    def set_branch_office
      @branch_office = current_account.entity_specific.branch_offices.find_by(id: params[:id]) if params[:id]
    rescue => e
      puts e.message.to_s.red
      redirect_to setup_company_path
    end

    def branch_office_params
      params.require(:branch_office).permit(BranchOffice.allowed_attributes)
    end
  end
end
