json.id account.id
json.email account.email
json.active account.active
json.person do
  json.first_name account.account_first_name
  json.last_name account.account_last_name
end
json.authentication_token account.authentication_token
json.suite_sessions account.suite_sessions
json.id_printer account.id_printer
json.created_at account.created_at
json.company do
  json.id account.company_id
  json.name account.entity_name
  json.active account.company_active
  json.debtors account.company_debtors
  json.first_owner_id account.company_first_owner_id
  json.second_owner_id account.company_second_owner_id
  json.platform_version account.company_platform_version
  json.phone account.account_phone
  json.setup_flow do
    json.commercial account.company_commercial_flow
    json.administrative account.company_administrative_flow
    json.operative account.company_operative_flow
    json.plan account.company_plan_flow
  end
  json.created_at account.company_created_at
end
json.google_sheet_link account.current_google_spreadsheet_link
json.service do
  json.partial! 'v/v4/accounts/service', service: account.entity.specific.active_service
end
