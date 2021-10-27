class NewUserMailer < ApplicationMailer
  default from: 'Shipit <new_user@shipit.cl>'
  def user_created(user)
    @user = user
    mail(to: 'nuevosclientes@shipit.cl', subject: '¡Se ha creado un nuevo usuario!') do |format|
      format.mjml { render 'user_created' }
    end
  end

  def instructions(user)
    mail(to: user.email, subject: 'Instrucciones para crear un pickup  🚛') do |format|
      format.mjml { render 'instructions' }
    end
  end

  def area_assign(company, branch_office, type = 'automatic')
    @company = company
    @branch_office = branch_office
    @location = @branch_office.location
    @type = type
    mail(to: 'teamoperaciones@shipit.cl', bcc: ['hirochi@shipit.cl'], subject: "🗺 Nueva Asignacion de area #{type}") do |format|
      format.mjml { render 'area_assign' }
    end
  end

  def area_error(company, branch_office)
    @company = company
    @branch_office = branch_office
    @location = @branch_office.location
    mail(to: 'teamoperaciones@shipit.cl', bcc: ['hirochi@shipit.cl'], subject: "😠 Error al asignar tratar de asignar area #{@company.name}") do |format|
      format.mjml { render 'area_error' }
    end
  end

  def fulfillment_request(user, params)
    @user = user
    @params = params
    mail(to: 'solicitudfulfillment@shipit.cl', bcc: ['nelson@shipit.cl', 'hirochi@shipit.cl'], subject: '🏪 Nueva solicitud cliente fulfillment') do |format|
      format.mjml { render 'fulfillment_request' }
    end
  end

  def marketplace_request(user, params)
    @user = user
    @params = params
    mail(to: ['carolina@shipit.cl', 'allan@shipit.cl'], bcc: ['hirochi@shipit.cl'], subject: '🏬 Nueva solicitud cliente marketplace') do |format|
      format.mjml { render 'marketplace_request' }
    end
  end
end
