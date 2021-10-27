class NotificationsController < ApplicationController
  before_action :set_company, only: %i[index update by_company]
  before_action :set_notification, only: %i[index update by_company]

  def index; end

  def by_company
    render json: { notification: @notification, company: @company, logo: @company.logo.url(:small) }, status: :ok
  end

  def update
    if @notification.update(settings_params)
      render json: { notification: @notification, company: @company, logo: @company.logo.url(:small) }, status: :ok
    else
      render json: { notification: @notification, company: @company, logo: @company.logo.url(:small) }, status: :error
    end
  rescue => e
    puts "😭\t#{e.message}".red
    flash[:danger] = 'No se actualizaron los datos, favor intenta más tarde'
    render json: { message: 'error al actualizar su configuracion' }, status: :error
  end


  private

  def set_company
    @company = current_account.entity_specific
    @fulfillment = @company.fulfillment?
  end

  def set_notification
    @notification = Setting.notification(@company.id)
  end

  def settings_params
    param = params.require(:setting).permit!
    param[:configuration] = params[:setting][:configuration].as_json
    param
  end
end
