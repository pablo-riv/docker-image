class Accounts::RegistrationsController < Devise::RegistrationsController
  layout 'sign_up'
  before_action :configure_sign_up_params, only: [:create]
  before_action :redirect_to_suite, only: [:new]
  before_action :set_how_to_know_options, only: [:new]
  before_action :validate_properties, only: [:create]
# before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    build_resource({})
    # self.resource.entity = Entity.new
    respond_with self.resource
  end

  # POST /resource
  def create
    Account.transaction do
      raise @errors unless @errors.size.zero?

      build_resource(configure_sign_up_params)
      unless resource.password == resource.password_confirmation
        flash[:danger] = 'La contraseña no coincide'
        redirect_back(fallback_location: { action: :sign_up })
        raise ActiveRecord::Rollback
      end
      company = create_company
      raise ActiveRecord::Rollback unless company.save(validate: false)
      company.generate_relation
      person = resource.generate_relation
      resource.entity_id = company.acting_as.id
      resource.person_id = person.id
      raise ActiveRecord::Rollback unless resource.save(validate: false)
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          redirect_to after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        flash[:danger] = resource.errors
      end
    end
  rescue => e
    Rails.logger.info { e.message.to_s.red.swap }
    Rails.logger.info { e.backtrace[0].red.swap }
    flash[:danger] = @errors
    redirect_back(fallback_location: { action: :sign_up })
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  private

  def redirect_to_suite
    return redirect_to 'https://app.shipit.cl/signup'
  end

  def set_how_to_know_options
    @questions = ['Me lo recomendó un amigo', 'Ví a Shipit en la calle', 'Me contactó un vendedor', 'Lo ví en las RRSS', 'Lo encontré buscando en internet', 'Lo leí en una nota en la prensa', 'Otros']
  end

  def validate_properties
    @errors = []
    @errors << "El cliente #{configure_sign_up_params[:company_name]} ya existe" if Entity.companies.where('LOWER(name) = ?', configure_sign_up_params[:company_name].try(:downcase)).present?
    @errors << 'El Email ingresado ya esta siendo utilizado.. Ingrese otro por favor' if Account.where(email: configure_sign_up_params[:email]).count.positive?
  end

  def create_company
    first_owner = Salesman.find_by(email: configure_sign_up_params[:seller_email])
    Company.new(name: configure_sign_up_params[:company_name],
                term_of_service: true,
                know_size_restriction: true,
                know_base_charge: true,
                capture: configure_sign_up_params[:company_capture],
                first_owner_id: first_owner.try(:id) || 14,
                second_owner_id: first_owner.try(:id) || 14,
                sales_channel: { names: [], categories: [] })
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    fields = [:email, :password, :password_confirmation, :company_name, :term_of_service, :know_size_restriction, :know_base_charge, :seller_email, :company_capture, how_to_know_shipit: [:how_to_know, :from]]
    params.require(resource_name).permit(fields)
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    setup_company_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end
end
