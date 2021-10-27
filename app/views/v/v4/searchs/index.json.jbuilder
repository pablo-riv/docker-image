partial_required = @search[:data].class == Array ? 'v/v4/shipments/search_shipment' : 'v/v4/shipments/shipment'
json.shipments do
  json.total @search[:total]
  json.data @search[:data], partial: partial_required, as: :shipment, origin: @branch_office.default_origin
end
