class TrackingNumberMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)
  default from: 'Shipit <no-reply@shipit.cl>'

  def buyer(package)
    @package = package
    @store = package.branch_office
    mail(to: @package.email, subject: "#{@store.name} te ha enviado un producto con el siguiente número de seguimiento")
  end
end
