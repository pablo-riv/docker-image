class V::V2::WebhooksController < V::ApplicationController
  before_action :set_webhook, only: %i[update show]

  def show
    Setting.transaction do
      respond_with(@webhook)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Setting.transaction do
      @webhook.configuration['pp']['webhook']['package'] = webhook_params
      raise unless @webhook.update_columns(configuration: @webhook.configuration)

      respond_with(@webhook)
    end
  rescue => e
    render_rescue(e)
  end

  private

  def set_webhook
    @webhook = Setting.pp(company.id)
    raise 'Sin configuracion disponible' unless @webhook.present?
  rescue StandardError => e
    render_rescue(e)
  end

  def webhook_params
    params.require(:webhook).permit(:url, options: [sign_body: [:required, :token], authorization: [:required, :kind, :token]])
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :unprocessable_entity
  end
end
