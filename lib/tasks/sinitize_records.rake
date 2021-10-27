namespace :sanitize_records do
  desc 'Delete all test accounts and it dependencies'
  task delete_account_test: :environment do
    Entity.transaction do
      logs = []
      Entity.where(actable_type: 'Company').where("name like '%test%'").each do |company|
        company_name = company.name
        logs.push("❌ TEST company 🏬 #{company_name}".green) if company.destroy
      end
      logs.each { |l| puts l }
    end

    Account.transaction do
      logs = []
      Account.where("email like '%test%'").each do |account|
        account_data = "🏭 #{account.email} #{account.person.first_name} #{account.person.last_name}"
        logs.push("❌ TEST account #{account_data}".green) if account.destroy
      end
      logs.each { |l| puts l }
    end
  end

  desc 'update all bootic config'
  task update_bootic_config: :environment do
    Setting.all.each do |setting|
      next unless setting.service_id == 2
      setting.configuration['fullit']['sellers'][1]['bootic']['authorization_token'] = ''
      setting.configuration['fullit']['sellers'][1]['bootic']['client_id'] = ''
      setting.configuration['fullit']['sellers'][1]['bootic']['client_secret'] = ''
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Delete history files'
  task delete_history_files: :environment do |_t|
    files = Dir.glob(File.join(Rails.root, 'public', '*.xls'))
    filesx = Dir.glob(File.join(Rails.root, 'public', '*.xlsx'))
    File.delete(*files) if files.count.positive?
    File.delete(*filesx) if filesx.count.positive?
  end
end
