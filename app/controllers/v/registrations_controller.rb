class V::RegistrationsController < Devise::RegistrationsController
  skip_before_action :verify_authenticity_token
  before_action :filter_format, only: %i[create]
  before_action :set_partner, only: %i[create]
  before_action :configure_permitted_parameters, if: :devise_controller?

  def create
    # Find hubspot contact with email params
    hubspot_contact = HubspotService::Bridge.find_contact_by_email(configure_permitted_parameters[:email])
    has_hubspot_contact = (hubspot_contact.present? && hubspot_contact['status'] != 'error')
    contact =
      if has_hubspot_contact
        hubspot_contact['properties'].inject({}) do |object, value|
          object.merge(value.first => value[1]['value'])
        end
      else
        {}
      end
    raise 'Debes incluir un nombre de compañía' unless params[:account][:company_name].present?

    registration = RegistrationService.new(has_hubspot_contact: has_hubspot_contact,
                                           suite: params[:account],
                                           contact: HashWithIndifferentAccess.new(contact),
                                           partner: @partner)
    @account = registration.create

    render 'v/v4/accounts/login.json', status: :ok
  rescue => e
    render_rescue(e)
  end

  private

  def filter_format
    if request.format != :json
      render status: :not_acceptable, json: { message: 'The request must be JSON' }
      return
    end
  end

  def render_rescue(exception)
    Rails.logger.info { "#{exception.message}\n#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def set_partner
    @partner = Partner.find_by(code: params[:account][:ref]) if params[:account][:ref]
  rescue => e
    puts "ERROR: #{e.message}\nBUG: #{e.backtrace[0]}".red.swap
  end

  protected

  def configure_permitted_parameters
    fields = [:email, :password, :password_confirmation, :company_name, :company_description, :term_of_service, :know_size_restriction, :know_base_charge, :seller_email, :company_capture, how_to_know_shipit: [:how_to_know, :from]]
    params.require(:account).permit(fields)
  end
end
