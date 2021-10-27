namespace :spreadsheet do
  desc 'refill credentials for v5'
  task refill: :environment do
    session = GoogleDrive.saved_session('config/config.json')
    BranchOffice.all.each do |branch_office|
      spreadsheet = session.spreadsheet_by_title("[Shipit] Pedidos #{branch_office.entity.name} V5")

      next if spreadsheet.nil?
      account = Account.find_by(email: spreadsheet.worksheet_by_title('Only For Shipit')[2, 1])
      next if account.nil?
      ws = spreadsheet.worksheet_by_title('Only For Shipit')
      ws[2, 1] = account.email
      ws[2, 2] = account.authentication_token
      ws.save

      client = account.entity_specific.default_branch_office
      new_spreadsheet_url = spreadsheet.human_url
      client.google_sheet_link = new_spreadsheet_url
      client.save(validate: false)
    end
  end
end
