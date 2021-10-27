module Setup
  class PeopleController < ApplicationController
    layout 'setup'
    before_action :set_person, only: [:edit, :update]
    before_action :set_setting, only: [:update]

    def edit
      @person
    end

    def update
      if @person.update(person_params)
        Publisher.publish('companies', current_account.entity_specific.send_new_company)
        redirect_to dashboard_path
      else
        flash[:danger] = @person.errors.full_messages
        redirect_back(fallback_location: { action: :edit })
      end
    rescue => e
      puts e.message.to_s.red
      flash[:danger] = 'No se pudo actualizar la información...'
      redirect_back(fallback_location: { action: :edit })
    end

    private

    def set_person
      @person = current_account.person
    end

    def set_setting
      @company = current_account.entity_specific
      @setting = Setting.find(@company.settings.first) if @company.settings.first
    rescue => e
      redirect_back(fallback_location: { action: :edit })
    end

    def person_params
      params.require(:person).permit(Person.allowed_attributes)
    end
  end
end
