class V::V4::Setups::SubscriptionsController < V::ApplicationController
  include Subscriptions
  before_action :set_company
  before_action :set_subscription, only: %i[show update create activate change_plan]
  before_action :set_plan, only: %i[update create]

  def show
    respond_with(@subscription)
  end

  def create
    @subscription = Subscriptions::SubscriptionService.new(@company.id, HashWithIndifferentAccess.new(subscriptions_params)).generate
    Subscription.transaction do
      raise 'Error al guardar el registro' unless @subscription.save
    end

    @company.update_columns(plan_flow: DateTime.current.to_s)
    respond_with(@subscription)
  rescue => e
    render_rescue(e)
  end

  def update
    Subscription.transaction do
      raise 'Error actualizando suscripción' unless @subscription.update(prices: subscriptions_params[:prices],
                                                                         application_list: subscriptions_params[:application_list],
                                                                         operations: subscriptions_params[:operations],
                                                                         configurations: subscriptions_params[:configurations],
                                                                         functionalities: subscriptions_params[:functionalities])

      respond_with(set_subscription)
    end
  rescue => e
    render_rescue(e)
  end

  def change_plan
    Subscription.transaction do
      properties = HashWithIndifferentAccess.new(plan_id: subscriptions_params['plan_id'],
                                                 is_active: true,
                                                 agreement_date: DateTime.current.to_s,
                                                 expiration_date: (DateTime.current + 1.months).to_s)
      @new_subscription = Subscriptions::SubscriptionService.new(@company.id, properties).generate
      raise 'Error actualizando suscripción' unless @new_subscription.save
      raise 'Error actualizando suscripción' unless @subscription.update(is_active: false)

      respond_with(@new_subscription)
    end
  rescue => e
    render_rescue(e)
  end

  def activate
    Subscription.transaction do
      raise 'Error activando suscripción' unless @subscription.update(:is_active, true)

      respond_with(set_subscription)
    end
  rescue => e
    render_rescue(e)
  end

  private

  def set_subscriptions
    @subscriptions = @company.subscriptions
  rescue => e
    render_rescue(e)
  end

  def set_plan_name
    @plan_name = @company.current_subscription.plan_name
  rescue => e
    render_rescue(e)
  end

  def set_subscription
    @subscription = @company.current_subscription
  end

  def set_plan
    @plan = Plan.find_by(id: subscriptions_params['plan_id'])
  end

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def subscriptions_params
    params.require(:subscription).permit(Subscription.allowed_parameters)
  end
end
