module Setup
  class SettingsController < ApplicationController

    before_action :set_service, only: [:edit, :update]
    before_action :set_setting, only: [:edit, :update]

    def edit
      @setting
    end

    def update
      if @setting.update(settings_params)
        Publisher.publish('companies', current_account.entity_specific.send_new_company)
        #Infusionsoft.new.create_contact(current_account) if Rails.env.production?
        redirect_to dashboard_path
      else
        redirect_back(fallback_location: { action: :edit })
      end
    rescue => e
      puts "😭\t#{e.message}".red
      flash[:danger] = 'No se pudo actualizar la información...'
      redirect_back(fallback_location: { action: :edit })
    end

    private

    def set_setting
      @setting = Setting.find(params[:id]) if params[:id]
    rescue => e
      redirect_back(fallback_location: { action: :edit })
    end

    def set_service
      @service = Service.find(params[:service_id]) if params[:service_id]
    rescue => e
      puts "😭\t#{e.message}".red
      redirect_back(fallback_location: { action: :edit })
    end

    def settings_params
      params.require(:setting).permit(Setting.allowed_attributes)
    end
  end
end
