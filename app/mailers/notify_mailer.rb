class NotifyMailer < ApplicationMailer
  default from: 'Shipit <envios@shipit.cl>'

  def without_address(email)
    mail(to: email, bcc: ['alertasenvios@shipit.cl'], subject: 'Necesitamos tu dirección de retiro!') do |format|
      format.mjml { render 'without_address' }
    end
  end

  def area_not_assign(company, branch_office, area)
    @company = company
    @branch_office = branch_office
    @area = area
    mail(to: 'carolina@shipit.cl', bcc: ['hirochi@shipit.cl'], subject: '😠 No se asignó área a cliente!') do |format|
      format.mjml { render 'area_not_assign' }
    end
  end

  def package_without_hero(template, branch_office)
    @packages = template[:packages]
    @branch_office = branch_office
    mail(to: 'hirochi@shipit.cl', subject: '😠  Envío sin héroe asignado!') do |format|
      format.mjml { render 'package_without_hero' }
    end
  end

  def company_change_address(company)
    @company = company
    mail(to: 'heroes@shipit.cl', bcc: 'hirochi@shipit.cl', subject: '🚀  Cliente ha modificado su direccion de retiro') do |format|
      format.mjml { render 'company_change_address' }
    end
  end

  def download_packages(file_name: '', file_path: '', subject: '', email: '')
    attachments["#{file_name}.xls"] = File.read(file_path)
    mail(to: email, bcc: ['zamiz@shipit.cl', 'hirochi@shipit.cl'], subject: subject) do |format|
      format.mjml { render 'download_packages' }
    end
  end

  def download_fulfillment_charges(type, account)
    @account = account
    @type = type
    attachments["Cobros Fulfillment #{account.entity.name} - #{type}.xls"] = File.read("#{Rails.root}/public/Cobros Fulfillment #{account.entity.name} - #{type}.xls")
    mail(to: account.email, bcc: 'hirochi@shipit.cl', subject: "💸 Cobros Fulfillment #{account.entity.name} - #{type}") do |format|
      format.mjml { render 'download_fulfillment_charges' }
    end
  end

  def labels(link, company, account)
    @link = link
    @company = company
    @account = account
    # attachments["Etiquetas #{account.entity.name}.pdf"] = File.read(open(link))
    mail(to: account.email, bcc: 'hirochi@shipit.cl', subject: "Shipit - Etiquetas") do |format|
      format.mjml { render 'labels' }
    end
  end
end
