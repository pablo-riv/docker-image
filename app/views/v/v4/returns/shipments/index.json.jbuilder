json.shipments @shipments, partial: 'v/v4/returns/shipments/shipment', as: :shipment, origin: @company.default_origin
json.total @total
