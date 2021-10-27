class V::V4::AppsCollectionsController < V::ApplicationController
  before_action :set_company
  before_action :set_subscription
  before_action :set_apps_slots, only: [:create]
  before_action :set_apps_availables, only: [:create]
  before_action :set_apps_slots_availables, only: [:create]
  before_action :set_app, only: [:create]

  def create
    raise 'Esta aplicación no está disponible para tu plan' unless @apps_availables.include?(apps_collection_params[:application][:app])
    raise 'No cuentas con slots disponibles' unless @slots > 0 || @slots < @total_slots
    AppsCollection.transaction do
      @app_collection = AppsCollection.create(subscription_id: @subscription.id, app_id: @app.id,
                                              active: apps_collection_params[:application][:active],
                                              is_installed: apps_collection_params[:application][:is_installed],
                                              installation_date: apps_collection_params[:application][:installation_date])
      raise 'Error instalando app' unless @app_collection.save
      update_slots
      respond_with(@app_collection)
    end
  rescue => e
    render_rescue(e)
  end

  private

  def update_slots
    Subscription.transaction do
      @subscription.configurations['apps_slots_availables'] = @slots - 1
      raise 'Error instalando , revise su configuración' unless @subscription.save
    end
  rescue => e
    render_rescue(e)
  end

  def set_apps_availables
    @apps_availables = @subscription.application_list
  end

  def set_apps_slots_availables
    @slots = @subscription.configurations['apps_slots_availables']
  end

  def set_apps_slots
    @total_slots = @subscription.configurations['apps_slots']
  end

  def set_subscription
    @subscription = @company.subscriptions.last
  rescue => e
    render_rescue(e)
  end

  def set_app
    @app = App.find_by(name: apps_collection_params[:application][:app])
  end

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def apps_collection_params
    params.require(:subscription).permit(application: [:app, :active, :is_installed, :installation_date])
  end
end
