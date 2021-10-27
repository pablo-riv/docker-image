module Returns
  class PackagesController < ApplicationController
    before_action :set_company, only: %i[create operation index]
    before_action :set_service, only: %i[create operation index]
    before_action :set_packages, only: %i[operation]
    before_action :set_returned, only: %i[create]
    before_action :set_package, only: %i[create]
    before_action :validate_return, only: %i[create]
    before_action :build_return, only: %i[create]

    def index; end

    def new; end

    def operation
      render json: { packages: @packages, total_packages: @total_packages }, status: :ok
    end

    def create
      raise StandardError unless @return.save!
      raise StandardError unless @returned.update_columns(status: :returned, sub_status: 'returned', return_retry_date: DateTime.current)

      ReturnsMailer.buyer(@company, @return).deliver if Restriction.find_by(kind: 'available_return_emails').active
      flash[:success] = 'Envío creado correctamente. Se entregará al courier el día ' + @return.operation_date.strftime('%d/%m/%Y')
    rescue StandardError => e
      puts e.message.red
      flash[:danger] = 'Error al crear devolución, verifique que haber llenado todos los campos'
    end

    def to_client
      packages = current_account.entity_specific.packages.where(id: params[:ids]).ids
      raise StandardError unless ReturnToClientJob.perform_later(packages)

      render json: { state: :ok }, status: :ok
    rescue StandardError => e
      Rails.logger.info { "ERROR: #{e.message}\nBUGTRACE #{e.backtrace}".red.swap }
      render json: { state: :error, message: e.message }, status: :bad_request
    end

    private

    def set_packages
      @packages = ActiveRecord::Type::Boolean.new.cast(params[:processed]) ? Package.returned_processed(current_account) : Package.returned_select(current_account)
      @total_packages = @packages.size
      @packages = @packages.select_processed_active.page(params[:page]).per(params[:per]).order(return_created_at: :desc)
    end

    def return_params
      params.require(:package).permit(Package.returned_attributes)
    end

    def set_returned
      @returned = Package.find_by(id: params[:package][:id])
    end

    def set_company
      @company = current_account.entity_specific
    end

    def set_package
      @package = @company.packages.includes(:commune, :address).find_by(id: params[:package][:id]) if params[:package][:id]
      raise 'Sin Package' if @package.nil?
    rescue StandardError => e
      flash[:danger] = 'Package buscado no existe.'
      puts e.message.to_s.red
      redirect_back(fallback_location: { action: :index })
    end

    def validate_return
      raise 'No es posible generar el pedido' unless @package.returnable_by_client
    rescue => e
      flash[:danger] = e.message
      redirect :back
    end

    def build_return
      @return = Package.new(return_params)
      @return.reference = "D#{@return.reference[0..13]}"
      @return.father_id = @returned.id
      @return.position = @returned.position
      raise 'Envio duplicado' if @company.packages.where(reference: @return.reference).present?
    rescue => e
      flash[:danger] = e.message
      redirect :back
    end

    def set_service
      @setting_fulfillment = @company.services.find_by(name: 'fulfillment')
      @setting_notification = @company.settings.find_by(service_id: 6)
    end
  end
end
