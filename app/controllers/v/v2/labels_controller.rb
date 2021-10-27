class V::V2::LabelsController < V::ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :set_company, only: [:create]
  before_action :set_packages, only: [:create]

  def create
    raise('No tienes envíos por imprimir') if @packages.blank?

    link = Opit.generate_avery(packages, nil, 'v1')
    @company.prints.create(quantity: @packages.size)
    @packages.update_all(label_printed: true, printed_date: Date.current)
    render json: { state: :ok, link: link }, status: :ok
  rescue RuntimeError => e
    render json: { state: :error, message: e.message.to_s }, status: :not_found
  rescue => e
    render json: { state: :error, message: e.message.to_s }, status: :bad_request
  end

  private

  def set_company
    @company = current_account.current_company
  end

  def set_packages
    @packages = @company.packages.today_packages_with_exception.no_returned.order('packages.created_at DESC')
  end

  def packages_params
    params.require(:packages).permit(Package.allowed_attributes)
  end
end
