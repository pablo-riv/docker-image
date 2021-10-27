json.extract! @account, :id, :email, :active, :person, :authentication_token, :entity, :id_printer, :created_at, :updated_at
json.google_sheet_link @account.current_google_spreadsheet_link
json.company @account.entity.specific
json.service do
  json.partial! 'v/v4/accounts/service', service: @account.entity.specific.active_service
end
