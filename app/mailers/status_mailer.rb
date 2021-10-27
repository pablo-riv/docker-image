class StatusMailer < ApplicationMailer
  default from: 'Shipit <no-reply@shipit.cl>'

  def success(package, store)
    @package = package
    @store = store
    mail(to: @store.email_notification, subject: "El envío #{@package.reference} ha sido entregado correctamente") do |format|
      format.mjml { render 'success' }
    end
  end

  def failed(package, store)
    @package = package
    @store = store
    mail(to: @store.email_notification, subject: "El envío #{@package.reference} ha tenido incidencias en su entrega") do |format|
      format.mjml { render 'failed' }
    end
  end
end
