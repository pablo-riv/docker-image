class V::V4::NotificationsController < V::ApplicationController
  before_action :set_company
  before_action :set_notifications, only: %i(index)
  before_action :set_notification, only: %i(show update destroy active test)
  before_action :set_setting_notification, only: %i(active setting show)
  before_action :inject_notification_params, only: %i(show)

  def index
    respond_with(@notifications)
  end

  def show
    respond_with(@notification, @company)
  end

  def update
    MailNotification.transaction do
      raise unless @notification.update(notification_params)
      
      inject_notification_params
      respond_with(@notification)
    end
  rescue => e
    render_rescue(e)
  end

  def setting
    respond_with(@setting)
  end

  def active
    @setting.configuration['notification'] = params[:notification]
    raise unless @setting.update_columns(configuration: @setting.configuration)

    respond_with(@setting)
  rescue => e
    render_rescue(e)
  end

  def preference
    respond_with(@company)
  rescue => e
    render_rescue(e)
  end

  def update_preference
    raise unless @company.update_preference(preference_params)

    respond_with(@company)
  rescue => e
    render_rescue(e)
  end

  def test
    if @notification.send_test(current_account, params[:emails])
      render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :ok
    else
      render json: { mail: @mail, company: @company, logo: @company.logo.url(:small) }, status: :bad_request
    end
  end

  private

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def set_notification
    @notification = @company.mail_notifications.find_by(state: params[:state])
  end

  def inject_notification_params
    Notification.find_by(name: @notification.state).text_notification.each do |notification|
      @notification[:text][notification.paragraph_notification.name.to_s] =
        { content: define_content(notification, notification.paragraph_notification.name), customizable: notification.customizable }
    end
  end

  def set_notifications
    @notifications = @company.mail_notifications
  end

  def notification_params
    params.require(:notification).permit!
  end  

  def set_setting_notification
    @setting = Setting.notification(@company.id)
  end

  def preference_params
    params.require(:company).permit(Company.allowed_attributes)
  end

  def define_content(notification, name)
    notification.customizable ? @notification.text[name] : notification.text
  end
end
