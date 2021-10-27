class V::V4::AnalyticsController < V::ApplicationController
  before_action :set_company
  before_action :set_analytics, only: [:index, :operational]

  def index
    @analytics = @analytic_generator.metrics
    respond_with(@analytics)
  rescue => e
    render_rescue(e)
  end

  def operational
    @analytics = @analytic_generator.operational_metrics
    respond_with(@analytics)
  rescue => e
    render_rescue(e)
  end

  def pickups
    @analytic_generator = Analytics::AnalyticGenerator.new(model: params[:model], company: @company)
    @pickups = @analytic_generator.pickups
    respond_with(@pickups)
  rescue => e
    render_rescue(e)
  end

  def charts
    analytic_generator = Analytics::AnalyticGenerator.new(kind: params[:kind], model: params[:model], company: @company, period: params[:days])
    @chart = analytic_generator.charts
    respond_with(@chart)
  rescue => e
    render_rescue(e)
  end

  private

  def set_analytics
    @analytic_generator = Analytics::AnalyticGenerator.new(models: params[:models], company: @company, period: params[:days])
    raise unless @analytic_generator.present?
  rescue => e
    render_rescue(e)
  end

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
