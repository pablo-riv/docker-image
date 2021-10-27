class V::V4::CompaniesController < V::ApplicationController
  def index
    raise 'No tienes autorización para consultar este recurso' unless current_account.id == 1

    @accounts = Account.joins('INNER JOIN entities e ON e.id = accounts.entity_id')
                       .joins('INNER JOIN people p on accounts.person_id = p.id')
                       .joins("INNER JOIN companies c on c.id = e.actable_id AND LOWER(e.actable_type) = 'company'")
                       .where('c.platform_version = 3 AND c.id = ?', params[:id]).where.not(id: 1).with_role(:owner)
                       .select_hack_data.distinct('accounts.id').load
    respond_with(@accounts)
  rescue => e
    render_rescue(e)
  end

  private

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
