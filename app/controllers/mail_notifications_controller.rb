class MailNotificationsController < ApplicationController
  before_action :set_company, only: %i[edit show update test]
  before_action :set_mail, only: %i[show update test]
  before_action :inject_notification_params, only: %i(show)

  def edit
    @mail = MailNotification.find_by(state: params[:state], company_id: @company.id)
    raise('¡Configuracion del correo no encontrada!') unless @mail.present?
  end

  def show
    render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :ok
  end

  def update
    if @mail.update(mail_params)
      inject_notification_params
      render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :ok
    else
      render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :bad_request
    end
  end

  def test
    if @mail.send_test(current_account, params[:emails])
      render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :ok
    else
      render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :bad_request
    end
  end

  private

  def set_company
    @company = current_account.entity_specific
    @fulfillment = @company.fulfillment?
  end

  def set_mail
    @mail = MailNotification.find_by(id: params[:id], company_id: @company.id)
    raise('¡Configuracion del correo no encontrada!') unless @mail.present?
  rescue => e
    puts e.message
    flash[:danger] = '¡Configuracion del correo no encontrada!, favor contactanos a ayuda@shipit.cl indicando tu problema'
    redirect_to notifications_path
  end

  def mail_params
    params.require(:mail_notification).permit!
  end

  def inject_notification_params
    Notification.find_by(name: @mail.state).text_notification.each do |notification|
      @mail[:text][notification.paragraph_notification.name.to_s] =
        { content: define_content(notification, notification.paragraph_notification.name), customizable: notification.customizable }
    end
  end

  def define_content(notification, name)
    notification.customizable ? @mail.text[name] : notification.text
  end
end
