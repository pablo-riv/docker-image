module Headquarter
  class PackagesController < Headquarter::HeadquarterController
    before_action :set_packages, only: [:index, :by_branch_office]
    before_action :valid_request_time?, only: [:create]
    before_action :set_package, only: [:show]

    def index
      flash[:warning] = 'Sin envíos realizados.' if @packages.blank?
    rescue => e
      puts e.message.to_s.red
      redirect_to headquarter_dashboard_path
    end

    def new
      @package = current_account.entity_specific.packages.new
    end

    def show
      (redirect_to(headquarter_dashboard_path) && flash[:danger] = 'Envío buscado no existe...') if @package.nil?
    end

    def create
      Package.transaction do
        if @package.blank?
          @package = current_account.entity_specific.packages.new(package_params)
          raise ActiveRecord::Rollback, @package.errors unless @package.save!
        else
          raise ActiveRecord::Rollback, @package.errors unless @package.update!(package_params)
        end
        Publisher.publish('mass', Package.generate_template_for(3, [@package], current_account)) unless @package.same_day_delivery?
        render json: { state: :ok, package: @package, message: 'Envío creado' }, status: :ok
      end
    rescue StandardError => e
      puts e.message.to_s.red
      render json: { state: :error, error: e.message.to_s, message: (e.class == RuntimeError ? e.message : 'Favor ingresar todos los datos.') }, status: :bad_request
    rescue ActiveRecord::RecordInvalid => e
      puts e.message.to_s.red
      render json: { state: :error, message: message, errors: e.record.errors }, status: :bad_request
    end

    def by_branch_office
      render json: { state: :ok, packages: @packages }, status: :ok
    rescue => e
      puts e.message.to_s.red
      render json: { state: :ok, message: 'Hubo un error en el proceso, favor intentar más tarde' }, status: :ok
    end

    private

    def set_packages
      @packages = current_account.entity_specific.packages.map(&:serialize_data!)
    end

    def valid_request_time?
      @package = current_account.entity_specific.packages.today_packages_with_exception.find_by(reference: package_params[:reference])
    end

    def set_package
      @package = Package.includes(:commune, :address).find_by(id: params[:id]) if params[:id]
      raise 'Sin Package' if @package.nil?
    rescue => e
      flash[:danger] = 'El envío buscado no existe.'
      puts e.message.red
      redirect_back(fallback_location: { action: :index })
    end

    def package_params
      params.require(:package).permit(Package.allowed_attributes)
    end
  end
end
