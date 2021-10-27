class V::V4::PartnersController < V::ApplicationController
  before_action :set_partners, only: %i[index]
  before_action :set_partner, only: %i[show]

  def index
    respond_with(@partners)
  rescue StandardError => e
    render_rescue(e)
  end

  def show
    respond_with(@partner)
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def set_partners
    @partners = Partner.all
  end

  def set_partner
    @partner =
      if params[:ref]
        Partner.find_by(code: params[:ref])
      else
        Partner.find_by(id: params[:id])
      end
    raise 'NOT_FOUND' unless @partner.present?
  rescue StandardError => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
