class AnalyticsMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  add_template_helper(AnalyticsHelper)
  default from: 'Shipit <no-reply@shipit.cl>'

  def analytics(emails, data)
    @data = data
    mail(to: emails, subject: 'Reporte programado') do |format|
      format.mjml { render 'analytics' }
    end
  end
end
