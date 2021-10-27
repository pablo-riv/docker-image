class OrderMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)
  default from: 'Shipit <envios@shipit.cl>'

  def warn_about_hero(packages, current_account, branch_office)
    @packages = packages
    @account = current_account
    @hero = branch_office.hero
    bcc = []

    bcc.push(branch_office.company.entity.email_contact) unless branch_office.company.entity.email_contact.blank?
    branch_office.company.entity.email_notification.split(',').each { |mail| bcc.push(mail) unless mail.blank? } unless branch_office.company.entity.email_notification.blank?
    mail(to:@account.email, bcc: bcc, subject: ' [Shipit] Tu solicitud de retiro está siendo procesada') do |format|
      format.mjml { render 'warn_about_hero' }
    end
  end

  def warn_about_something_happend(file, message)
    @message = message
    @file = file
    mail(to: 'michel@shipit.cl', bcc: [], subject: 'Ocurrió un problema') do |format|
      format.mjml { render 'warn_about_something_happend' }
    end
  end

  def warn_about_failure(current_account, branch_office)
    bcc = ['michel@shipit.cl', 'carolina@shipit.cl', 'nelson@shipit.cl']
    bcc.push(branch_office.company.entity.email_contact) unless branch_office.company.entity.email_contact.blank?
    branch_office.company.entity.email_notification.split(',').each { |mail| bcc.push(mail) unless mail.blank? } unless branch_office.company.entity.email_notification.blank?
    mail(to: current_account.email, bcc: bcc, subject: '[Shipit] Problemas con tu solicitud de retiro') do |format|
      format.mjml { render 'warn_about_failure' }
    end
  end

  def test_new_courier(csv_data)
    attachments['examples.csv'] = csv_data
    mail(to: 'hirochi@shipit.cl', subject: 'TEST 2000 envios')
  end

  def too_high(package, current_account, amount = 50_000)
    @package = package
    @account = current_account
    branch_office = current_account.current_branch_office
    @amount = amount
    bcc = ['alertasenvios@shipit.cl']

    bcc.push(branch_office.company.entity.email_contact) unless branch_office.company.entity.email_contact.blank?
    branch_office.company.entity.email_notification.split(',').each { |mail| bcc.push(mail) unless mail.blank? } unless branch_office.company.entity.email_notification.blank?
    mail(to:@account.email, bcc: bcc, subject: ' [Shipit-Alerta] Tu solicitud de envío tiene un costo demasiado alto') do |format|
      format.mjml { render 'too_high' }
    end
  end
end
