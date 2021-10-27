json.extract! shipment, :id, :reference, :courier_for_client, :status
json.address shipment.address.try(:serialize_shipment!)
json.shipped shipment.packages_pickups.last.shipped