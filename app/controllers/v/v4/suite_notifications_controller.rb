class V::V4::SuiteNotificationsController < V::ApplicationController
  before_action :set_company
  before_action :set_suite_notification, only: %i[show destroy]
  before_action :set_suite_notifications, only: %i[index]
  
  def index
    respond_with(@suite_notifications)
  end

  def show
    respond_with(@suite_notification)
  end

  def destroy
    @suite_notification.update_columns(is_archive: true)
    render json: { message: 'Notificación eliminada' }, status: :ok
  rescue => e
    render json: { message: e.message }, status: :bad_request
  end

  private

  def set_company
    @company = current_account.current_company
  end

  def set_suite_notification
    @suite_notification = @company.downloads.find_by(id: params[:id]) if params[:id]
    raise 'Notificación no encontrada' unless @suite_notification.present?
  rescue => e
    render json: { message: e.message }, status: :bad_request
  end

  def set_suite_notifications
    @data = @company.suite_notifications.order(updated_at: :desc)
    @suite_notifications = Kaminari.paginate_array(@data).page(params[:page]).per(params[:per])
  end
end
