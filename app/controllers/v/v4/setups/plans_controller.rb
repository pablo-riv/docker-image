class V::V4::Setups::PlansController < V::ApplicationController
  include Subscriptions
  before_action :set_plans, only: :index

  def index
    respond_with(@plans)
  end

  def set_plans
    @plans = Subscriptions::SubscriptionService.new(1, nil).plans_templates
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
