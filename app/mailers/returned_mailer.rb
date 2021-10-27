class ReturnedMailer < ApplicationMailer
  default from: 'Shipit <envios@shipit.cl>'

  def returned(packages, current_account)
    @packages = packages
    @account = current_account
    mail(to: 'alertasenvios@shipit.cl', subject: ' Se ingresó una devolución ') do |format|
      format.mjml { render 'returned' }
    end
  end
end
