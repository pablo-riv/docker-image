class HelpsController < ApplicationController
  before_action :set_translate, only: %i[supports]
  before_action :set_supports, only: %i[supports]
  before_action :set_support, only: %i[show]
  before_action :set_last_update, only: %i[syncronize]

  def index; end

  def show
    render json: { support: @support }, status: :ok
  rescue => e
    render json: { state: :error, message: e.message }, status: :bad_request
  end

  def supports
    render json: { supports: @supports }, status: :ok
  rescue => e
    render json: { state: :error, message: e.message }, status: :bad_request
  end

  def create
    Support.transaction do
      support = current_account.supports.create(support_params)
      render json: { support: support, state: :ok }, status: :ok
    end
  rescue => e
    Rails.logger.debug { "#{e.message}".red.swap }
    render json: { support: {}, message: e.message, state: :error }, status: :bad_request
  end

  def syncronize
    raise unless SyncronizeSupportJob.perform_now(current_account)
    render json: { message: 'Se ha encolado la tarea de actualización, esto puede tardar unos minutos', state: :ok }, status: :ok
  rescue => e
    render json: { message: e.message, state: :error }, status: :bad_request
  end

  private

  def set_supports
    @supports = current_account.supports.where(show_client: true).where('LOWER(status) similar to ?', @filter_ticket).order(id: :desc)
  end

  def set_support
    @support = current_account.supports.find_by(provider_id: params[:provider_id])
  end

  def set_last_update
    current_account.update_columns(last_update_zendesk_date: DateTime.current)
  end

  def support_params
    params.require(:support).permit(Support.allowed_attributes).as_json
  end

  def set_translate
    @filter_ticket = "%(#{I18n.t("activerecord.attributes.zendesk.ticket.status.#{params[:status]}")}|#{params[:status]})%"
  end
end
