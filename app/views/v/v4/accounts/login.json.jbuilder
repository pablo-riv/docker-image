json.extract! @account, :id, :email, :active, :person, :authentication_token, :id_printer, :suite_sessions, :created_at, :updated_at
json.company do
  current_company = @account.entity.specific
  json.id current_company.id
  json.name current_company.name
  json.key_account_manager current_company.key_account_manager
  json.need_key_account_manager current_company.need_key_account_manager
  json.priority current_company.priority
  json.base_charge current_company.base_charge
  json.base_packages current_company.base_packages
  json.active current_company.active
  json.debtors current_company.debtors
  json.hubspot_company_id current_company.hubspot_company_id
  json.hubspot_contact_id current_company.hubspot_contact_id
  json.first_owner_id current_company.first_owner_id
  json.second_owner_id current_company.second_owner_id
  json.know_base_charge current_company.know_base_charge
  json.know_size_restriction current_company.know_size_restriction
  json.term_of_service current_company.term_of_service
  json.bill_phone current_company.bill_phone
  json.bill_email current_company.bill_email
  json.bill_address current_company.bill_address
  json.business_turn current_company.business_turn
  json.business_name current_company.business_name
  json.capture current_company.capture
  json.logo_file_name current_company.logo_file_name
  json.sales_channel current_company.sales_channel
  json.email_domain current_company.email_domain
  json.last_delivery_date current_company.last_delivery_date
  json.category current_company.category
  json.platform_version current_company.platform_version
  json.suite_disable_count current_company.suite_disable_count
  json.suite_enable_count current_company.suite_enable_count
  json.expired_bill current_company.expired_bill
  json.definition current_company.definition
  json.package_monthly_range current_company.package_monthly_range
  json.nps_score current_company.nps_score
  json.phone @account.person_phone
  json.setup_flow do
    json.commercial current_company.commercial_flow
    json.administrative current_company.administrative_flow
    json.operative current_company.operative_flow
    json.plan current_company.plan_flow
  end
  json.updated_at current_company.updated_at
  json.created_at current_company.created_at
end
json.google_sheet_link @account.current_google_spreadsheet_link
json.service do
  json.partial! 'v/v4/accounts/service', service: @account.entity.specific.active_service
end
