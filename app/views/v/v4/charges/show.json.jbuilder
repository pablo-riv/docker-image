json.charges do
  if @charge[:service] == 'pick_and_pack'
    json.shipments @charge[:shipments]
    json.shipment_quantity @charge[:shipment_quantity]
    json.base @charge[:base]
    json.total_overcharge @charge[:total_overcharge]
    json.total_other_services @charge[:total_other_services]
    json.total_shipments @charge[:total_shipments]
    json.total_charges [@charge[:base], @charge[:total_overcharge], @charge[:total_other_services], @charge[:total_shipments]].sum
  else
    json.total_in @charge[:total_in]
    json.total_out @charge[:total_out]
    json.total_stock @charge[:total_stock]
    json.total_other_services @charge[:total_other_services]
    json.total_shipments @charge[:total_shipments]
    json.inventories @charge[:inventories]
    json.total_charges [@charge[:total_in], @charge[:total_out], @charge[:total_stock], @charge[:total_other_services], @charge[:total_shipments]].sum
  end
  # json.total_premium @charge[:total_premium]
  json.invoice charge[:invoice]
  json.total_refunds @charge[:total_refunds]
end
