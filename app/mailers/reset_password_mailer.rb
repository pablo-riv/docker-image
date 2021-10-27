class ResetPasswordMailer < ApplicationMailer
  default from: 'Shipit <no-reply@shipit.cl>'

  def code(account, code)
    @account = account
    @code = code
    mail(to: @account.email, subject: '🚨 Tu Código de autorización ha llegado...') do |format|
      format.mjml { render 'code' }
    end
  end
end
