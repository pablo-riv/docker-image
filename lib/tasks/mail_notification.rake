namespace :mail_notification do
  desc 'normalize title of notifications template sent rejected'
  task normalize_title_for_rejected_notification: :environment do
    rejected_templates = MailNotification.where(state: 'failed')
    copy = rejected_templates.first.text.dup
    copy[:title_text] = 'Paquete no pudo ser entregado'
    rejected_templates.each do |template|
      next unless template.text[:title_text].eql? 'Rechazado'

      template.update_columns(text: copy)
    end
  end
end
