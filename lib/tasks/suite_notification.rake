namespace :suite_notification do
  desc 'Create json backup'
  task create_backup: :environment do
    suite_notifications = SuiteNotification.all.to_json
    File.open('public/suite_notification.json', 'w') do |f|
      f.write(suite_notifications)
    end
  end

  task create_download_notifications: :environment do
    filepath = File.join(Rails.root, 'public', 'suite_notification.json')
    abort "Input file not found: #{filepath}" unless File.exist?(filepath)

    suite_notifications = JSON.parse(File.read(filepath))

    suite_notifications.each do |suite_notification|
      DownloadNotification.create(suite_notification: SuiteNotification.find(suite_notification['id']), status: suite_notification['status'], source: suite_notification['source'])
    end
  end

  task set_status_customer_satisfaction: :environment do
    SiteNotification.where(actable_type: 'CustomerSatisfaction')
                    .find_each(batch_size: 50)
                    .each do |site_notification|
      site_notification.update_columns(status: 'base')
    end
  end

  task set_status_pickup: :environment do
    SiteNotification.where(actable_type: 'Pickup')
                    .find_each(batch_size: 50)
                    .each do |site_notification|
      site_notification.update_columns(status: site_notification.actable.status == 'failed' ? 'failed' : 'pending')
    end
  end

  task set_status_incidence: :environment do
    SiteNotification.where(actable_type: 'Incidence')
                    .find_each(batch_size: 50)
                    .each do |site_notification|
      site_notification.update_columns(status: site_notification.actable.status)
    end
  end
end
