class V::V4::CalendarsController < V::ApplicationController
  before_action :set_company
  def index
    @data = CalendarService.new(status: calendar_params[:status],
                                courier: calendar_params[:courier],
                                date: calendar_params[:date],
                                branch_offices: @company.branch_offices.ids).calendar
    raise 'No se encuentran envios' if @data[:shipments].empty?

    respond_with(@data)
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def calendar_params
    params.permit(:status, :courier, :date)
  end
end
