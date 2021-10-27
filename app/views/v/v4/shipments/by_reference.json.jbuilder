json.shipments @shipments, partial: 'v/v4/shipments/shipment', as: :shipment, origin: @branch_office.default_origin
json.total @total
