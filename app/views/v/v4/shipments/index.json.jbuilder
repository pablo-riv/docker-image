partial_required = @shipments.class == Array ? 'v/v4/shipments/search_shipment' : 'v/v4/shipments/shipment'
json.shipments @shipments, partial: partial_required, as: :shipment, origin: @branch_office.default_origin
json.total @total
