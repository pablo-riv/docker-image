class V::V4::DownloadsController < V::ApplicationController
  before_action :set_company
  before_action :set_download, only: %i[show destroy]
  before_action :set_downloads, only: %i[index]

  def index
    respond_with(@downloads, @total)
  end

  def show
    respond_with(@download)
  end

  def destroy
    raise if %w[success failed].exclude?(@download.status)

    @download.update_columns(is_archive: true)
    render json: { message: 'Descarga eliminada' }, status: :ok
  rescue
    render json: { message: 'Descarga en progreso' }, status: :bad_request
  end

  private

  def set_downloads
    data = SearchService::Download.new(id: params[:id],
                                       status: params[:status],
                                       kind: params[:kind],
                                       per: params[:per],
                                       page: params[:page],
                                       company: @company).search
    @downloads = data[:downloads]
    @total = data[:size]
  end

  def set_download
    @download = @company.downloads.find_by(id: params[:id]) if params[:id]
    raise 'Descarga no encontrada' unless @download.present?
  rescue => e
    render json: { message: e.message }, status: :bad_request
  end

  def set_company
    @company = current_account.current_company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
