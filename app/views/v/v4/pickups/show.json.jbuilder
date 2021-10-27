json.pickup @pickup, partial: 'v/v4/pickups/pickup', as: :pickup
json.shipments @pickup.packages, partial: 'v/v4/pickups/shipment', as: :shipment
