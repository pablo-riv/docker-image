class MailingMailer < ApplicationMailer
  default from: 'Notificación Envío <no-reply@shipit.cl>'

  def failed(package)
    @package = package
    @branch_office = package.branch_office
    @company_name = @branch_office.name.gsub('Casa Matriz', '')
    if @branch_office.blank?
      puts "Sin email de contacto".red
    else
      puts "Enviando correo tracking".green
      mail(to: @branch_office.company.email_contact.split(",").map(&:strip), bcc: ['alertasenvios@shipit.cl'], subject: "🚨 La entrega del envío #{@company} / #{package.reference} ha fallado") do |format|
        format.text
        format.mjml
      end
    end
  end
end
