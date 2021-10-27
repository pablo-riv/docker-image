set :output, 'log/whenever.log'

ENV.each { |k, v| env(k, v) }

every 10.minutes do
 rake 'package:set_tracking'
end

#every 3.hours do
#  rake 'package:clear_scheduled_set_queue'
#end

#every :weekday, at: '05:00 am' do
#  rake 'package:confirm_price'
#end

every 1.day, at: '07:00 am' do
 rake 'sanitize_records:delete_history_files'
end

every 1.day, at: '04:00 am' do
 rake 'account:add_zendesk'
end

every '0 8 * * 1,5' do
  rake 'setting:scheduled_weekly_report'
end

every '0 7 1 1-12 *' do
  rake 'setting:scheduled_monthly_report'
end

every 1.week, at: '03:00 am' do
  rake 'tmp:cache:clear'
end

every :day, at: '03:30 am' do # 01:30 am
  rake 'package:package_accomplishment'
end

every :day, at: '21:55 pm' do # 08:30 am
  rake 'hubspot:update'
end

every :day, at: '04:00 am' do
  rake 'hubspot:migrate'
end

every :day, at: '06:00 am' do
  rake 'duemint:migrate_invoices'
end

every :day, at: '07:00 am' do
  rake 'duemint:update'
end

every :day, at: '05:00 am' do
  rake 'duemint:migrate'
end

#every :day, at: '02:30 am' do # 22:30 pm
#  rake 'kpi:set_daily_sla'
#end

every :day, at: '04:40 am' do
  rake 'demo:update'
end

every 7.minutes do
  rake 'package:set_price'
end

every :day, at: '00:00 am' do
 rake 'zendesk:sync_last_tickets'
end

every :weekday, at: '12:25 pm' do
  rake 'package:shipments_delayed'
end

every :weekday, at: '02:05 pm' do # 11:05 am (GMT-3)
  rake 'package:send_sdd_pickup_alert'
end

every :weekday, at: '02:05 pm' do # 11:05 am (GMT-3)
  rake 'package:send_heroes_pickup_alert'
end

every '00 13,14 * * 1-5' do
  rake 'pickup:generate_manifest'
end

every :day, at: '07:00 pm' do # 04:00 pm (GMT-3)
  rake 'return:pick_and_pack_process'
end

every 4.months, at: '05:00 am' do
  rake 'shopify_api_version:update'
end

every :day, at: '08:00 am' do # 05:00 am (GMT-3)
  rake 'setting:send_emergency_rates_to_integrations'
end

every '00 8,9,10,11,12,13,14,15 * * 1-5' do
  rake 'pickup_and_pack:generate_update_manifest'
end
