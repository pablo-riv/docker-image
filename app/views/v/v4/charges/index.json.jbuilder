json.charges do
  json.array! @charges do |charge|
    json.date charge[:date]
    json.shipping_price charge[:shipping_price]
    # json.premium charge[:premium]
    json.overcharges charge[:overcharges]
    json.plan charge[:plan]
    json.service_price charge[:service_price]
    json.refunds charge[:refunds]
    json.invoice charge[:invoice]
    json.state charge[:state]
    json.total charge[:total]
  end
end
