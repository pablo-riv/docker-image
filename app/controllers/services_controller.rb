class ServicesController < ApplicationController
  before_action :set_service, only: [:assign]
  before_action :set_setting, only: [:assign]
  before_action :set_services, only: [:assign]

  def index
    @services = Service.where(name: ['pp','fulfillment'])
  end

  def assign
    Setting.transaction do
      return redirect_to edit_service_setting_path(@service.id, @setting.id) if @account_services.pluck(:id).include?(@service.id)
      setting = @service.settings.build(company_id: current_account.entity.actable_id)
      if setting.save
        redirect_to edit_service_setting_path(@service.id, setting.id)
      else
        raise ActiveRecord::Rollback, "No se asignó el servicio #{@service.name}, intenta más tarde"
      end
    end
  rescue => e
    flash[:danger] = 'No se asignó el servicio, intenta más tarde'
    redirect_back(fallback_location: dashboard_path)
  end

  private

  def set_service
    @service = Service.find(params[:service_id]) if params[:service_id]
  rescue => e
    puts e.message.to_s.red
  end

  def set_setting
    @setting = current_account.entity.specific.settings.find_by(service_id: @service.id)
  rescue => e
    puts e.message.to_s.red
  end

  def set_services
    @account_services = current_account.entity.specific.services
  rescue => e
    puts e.message.to_s.red
  end
end
