class SpreadsheetsJob < ApplicationJob
  queue_as :default

  def perform(account, version)
    session = GoogleDrive.saved_session('config/config.json')
    client_key = account.authentication_token
    client_mail = account.email
    spreadsheet_name = account.has_role?(:owner) ? account.entity.specific.default_branch_office.name : "#{account.entity_specific.name}(#{account.entity_specific.company.name})"
    spreadsheet_base = session.spreadsheet_by_title('Shipit V6 - Suite base')
    spreadsheet_base.duplicate("[Shipit] Pedidos #{spreadsheet_name} #{version}")
    client_spreadsheet = session.spreadsheet_by_title("[Shipit] Pedidos #{spreadsheet_name} #{version}")
    client_worksheet = client_spreadsheet.worksheet_by_title('Only For Shipit')
    client_worksheet[2, 1] = client_mail
    client_worksheet[2, 2] = client_key
    client_worksheet.save
    client_spreadsheet.acl.push(type: 'user', value: client_mail, role: 'writer')
    client_spreadsheet.acl.push(type: 'user', value: 'carolina@shipit.cl', role: 'writer')
    client_spreadsheet.acl.push(type: 'user', value: 'hirochi@shipit.cl', role: 'writer')
    client_spreadsheet.acl.push(type: 'user', value: 'alertasti@shipit.cl', role: 'writer')

    # Anyone who knows the link can read / writer.
    # https://app.asana.com/0/778023032614361/873483342541695
    client_spreadsheet.acl.push(type: 'anyone', allow_file_discovery: false, role: 'writer')

    new_spreadsheet_url = client_spreadsheet.human_url
    branch_office = account.has_role?(:owner) ? account.entity_specific.default_branch_office : account.entity_specific
    branch_office.update_column(:google_sheet_link, new_spreadsheet_url)
  end
end
