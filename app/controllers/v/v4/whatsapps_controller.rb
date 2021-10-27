class V::V4::WhatsappsController < V::ApplicationController
  before_action :set_company
  before_action :set_notifications, only: %i(index)
  before_action :set_notification, only: %i(show update destroy active test)
  before_action :set_setting_notification, only: %i(active setting show)

  def index
    respond_with(@notifications)
  end

  def show
    respond_with(@notification, @company)
  end

  def update
    MailNotification.transaction do
      raise unless @notification.update(whatsapp_template_params)

      respond_with(@notification)
    end
  rescue => e
    render_rescue(e)
  end

  def setting
    respond_with(@setting)
  end

  def active
    @setting.configuration['notification']['buyer']['whatsapp']['state'][params[:state]].merge!(whatsapp_params[:whatsapp][:state][params[:state]])
    raise unless @setting.update_columns(configuration: @setting.configuration)

    respond_with(@setting)
  rescue => e
    render_rescue(e)
  end

  def test
    if @notification.send_test(current_account, params[:number])
      render json: { state: :ok, company: @company }, status: :ok
    else
      render json: { state: :error, company: @company }, status: :bad_request
    end
  end

  private

  def set_company
    @company = company
  end

  def set_notification
    @notification = @company.whatsapp_notifications.find_by(state: params[:state])
  end

  def set_notifications
    @notifications = @company.whatsapp_notifications
  end

  def whatsapp_params
    params.require(:buyer).permit(whatsapp: [state: [in_preparation: :active, in_route: :active, by_retired: :active, delivered: :active, failed: :active]])
  end

  def whatsapp_template_params
    params.require(:whatsapp_template).permit(:state, text: %i[one subject])
  end

  def set_setting_notification
    @setting = Setting.notification(@company.id)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
