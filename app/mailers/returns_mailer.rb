class ReturnsMailer < ApplicationMailer
  add_template_helper(PackagesHelper)

  default from: 'Shipit <ayuda@shipit.cl>'

  def client(company, package)
    @package = package
    @company = company
    mail(to: company.current_account.email, bcc: company.default_mailing_list, subject: "Pieza #{package.reference} enviada a tu dirección") do |format|
      format.mjml
    end
  end

  def buyer(company, package)
    @package = package
    @company = company
    mail(to: package.email, bcc: company.default_mailing_list, subject: "Nuevo intento de envío del producto comprado en la tienda: #{company.name}") do |format|
      format.mjml
    end
  end
end
