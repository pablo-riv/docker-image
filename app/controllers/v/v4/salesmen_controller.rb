class V::V4::SalesmenController < V::ApplicationController
  before_action :set_company
  before_action :set_salesman, only: %i[show]

  def show
    respond_with(@salesman)
  end

  def set_company
    @company = company
  end

  def set_salesman
    @salesman = Salesman.find_by(id: @company.first_owner_id)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, bug_trace: exception.backtrace, state: :error }, status: :bad_request
  end
end
