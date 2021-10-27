json.subscriptions @subscriptions do |subscription|
  json.company subscription.company_id
  json.plan subscription.plan_id
  json.active subscription.is_active
  json.init subscription.agreement_date
  json.finish subscription.expiration_date
  json.charging_frequency subscription.charging_frequency
end
