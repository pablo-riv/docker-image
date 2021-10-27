class V::V4::SearchsController < V::ApplicationController
  before_action :set_company
  before_action :set_branch_offfice
  before_action :set_search, only: %i[index]

  def index
    respond_with(@search)
  rescue => exception
    render_rescue(exception)
  end

  private

  def set_company
    @company = company
  end

  def set_branch_offfice
    @branch_office = branch_office
  end

  def set_search
    @search = SearchService::Search.new(company: @company,
                                        query: params[:query] || params[:reference],
                                        per: params[:per],
                                        page: params[:page]).search
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, bug_trace: exception.backtrace, state: :error }, status: :bad_request
  end
end
