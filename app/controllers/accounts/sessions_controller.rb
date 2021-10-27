class Accounts::SessionsController < Devise::SessionsController
  layout 'sign_in'
  skip_before_action :verify_authenticity_token, only: [:create]
  # before_action :configure_sign_in_params, only: [:create]
  after_action :prepare_intercom_shutdown, only: [:destroy]
  before_action :configure_sign_in_params, only: [:create]
  before_action :validate_user, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    if @user.current_company.platform_version == 3
      sign_out @user
      redirect_to 'http://app.shipit.cl/login'
    else
      super
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  def prepare_intercom_shutdown
    IntercomRails::ShutdownHelper.prepare_intercom_shutdown(session)
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    fields = %i[email password remember_me]
    params.require(resource_name).permit(fields)
  end

  def validate_user
    emails = ['demagiaycarton@gmail.com', 'demariechile@gmail.com', 'silvana@araf.cl', 'contacto@8-bits.cl', 'michele@uniqueshoes.cl', 'w.lecaros.h@gmail.com', 'gramirez.e@gmail.com', 'jesus@epic.cl', 'eguerra@posterhouse.cl', 'contacto@mariapompon.cl', 'silvia@craftbox.cl', 'cristobal@vitalmarket.cl', 'jgranifo@flexboards.cl', 'ssoza@restbar.cl', 'agago@cgcosmetics.cl', 'contacto@cadacosaensulugar.cl', 'josefina@urco.cl']
    return redirect_to 'https://app.shipit.cl/login' if emails.include?(configure_sign_in_params[:email])

    @user = Account.find_by(email: configure_sign_in_params[:email])
    unless @user.present?
      flash[:danger] = 'Correo no registrado, favor ingresar un correo valido...'
      redirect_to :back
    end
  end
end
