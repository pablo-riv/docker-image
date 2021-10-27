class V::V4::HelpsController < V::ApplicationController
  before_action :set_translate, only: %i[index]
  before_action :set_supports, only: %i[index]
  before_action :set_support, only: %i[show]
  before_action :set_last_update, only: %i[syncronize]

  def index
    respond_with(@supports)
  end

  def show
    respond_with(@support)
  rescue => e
    render_rescue(e)
  end

  def create
    Support.transaction do
      @support = current_account.supports.create(support_params)
      respond_with(@support)
    end
  rescue => e
    render_rescue(e)
  end

  def syncronize
    raise unless SyncronizeSupportJob.perform_later(current_account)

    render json: { message: 'Se ha encolado la tarea de actualización, esto puede tardar unos minutos', state: :ok }, status: :ok
  rescue => e
    render_rescue(e)
  end

  private

  def set_supports
    @supports = current_account.supports.where('LOWER(status) similar to ?', @filter_ticket).order(id: :desc)
    @supports = @supports.map do |ticket|
      ticket.messages = ticket.messages.select { |m| m['public'] == true }
      ticket
    end
  end

  def set_support
    @support = current_account.supports.find_by(provider_id: params[:provider_id])
    raise 'Ticket no encontrado' unless @support.present?

    @support.messages = @support.messages.select { |m| m['public'] == true }
  rescue => e
    render_rescue(e)
  end

  def set_last_update
    current_account.update_columns(last_update_zendesk_date: DateTime.current)
  end

  def support_params
    params.require(:support).permit(Support.allowed_attributes).as_json
  end

  def set_translate
    @filter_ticket = "%(#{I18n.t("activerecord.attributes.zendesk.ticket.status.#{zendesk_logic_for_shipit_client}")}|#{zendesk_logic_for_shipit_client})%"
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def zendesk_logic_for_shipit_client
    case params[:status].downcase
    when 'open' then 'pending'
    when 'pending' then 'open'
    else
      params[:status]
    end
  end
end
