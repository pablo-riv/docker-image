class TrackingMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)
  default from: 'Shipit - Número de Seguimiento <envios@shipit.cl>'

  def notify_client(company, packages)
    @company, @packages = company, packages

    contact_email = @company.accounts.first['email']

    if contact_email.blank?
      puts "Sin email de contacto".red
    else
      puts "Enviando correo trackings".green
      mail(to: contact_email, bcc: ['alertasenvios@shipit.cl'], subject: '🚚 Se han asignado los códigos de seguimiento a tus envíos') do |format|
        format.text
        format.mjml
      end
    end
  end

  def notify_failed_client(company, package)
    @company = company
    @package = package
    mail(to: @company.default_mailing_list, bcc: ['alertasenvios@shipit.cl'], subject: "😧 No hemos podido entregar tu pedido... 😧") do |format|
      format.mjml
    end
  end

  def state_to_buyer(package, mail, company, configuration)
    @package = package
    @mail = mail.inject_params
    @company = company
    cc = (configuration['cc'].blank? ? company.current_account.email : configuration['cc']) if configuration['state']['cc']
    mail(to: package.email.try(:strip), bcc: ['alertasenvios@shipit.cl', cc], subject: @mail.subject) do |format|
      format.text
      format.mjml
    end
  end

  def test_state_buyer(current_account, state, emails)
    @company = current_account.current_company
    @state = state
    @mail = @company.mail_notifications.by(state).last.inject_params
    mail(to: emails, bcc: ['hirochi@shipit.cl'], subject: @mail.subject) do |format|
      format.text
      format.mjml
    end
  end
end
