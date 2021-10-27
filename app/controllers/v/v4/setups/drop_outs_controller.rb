class V::V4::Setups::DropOutsController < V::ApplicationController
  include Subscriptions
  before_action :set_account
  before_action :set_drop_out

  def index
    respond_with(@drop_out)
  end

  def deactivate
    DropOut.transaction do
      @account = current_account
      @drop_out = @account.drop_outs.create(drop_out_params)
      raise unless @drop_out.present?

      render json: { message: 'Tu cuenta ha sido deshabilitada', state: :ok }, status: :ok
    end
  rescue StandardError => e
    render_rescue(e)
  end

  def reactivate
    DropOut.transaction do
      @account = current_account
      @drop_out = @account.drop_outs.last
      @reactivated_account = false
      if @drop_out.try(:deactivated)
        raise unless @drop_out.update(deactivated: false)

        @reactivated_account = true
        respond_with(@drop_out, @reactivated_account)
      else
        render json: { reactivated_account: @reactivated_account, state: :ok }, status: :ok
      end
    end

  rescue StandardError => e
    render_rescue(e)
  end

  def set_account
    @account = current_account
  end

  def set_drop_out
    @drop_out = current_account.drop_outs.last
  end

  def drop_out_params
    params.require(:drop_out).permit(:reason, :other_reason, :details)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
