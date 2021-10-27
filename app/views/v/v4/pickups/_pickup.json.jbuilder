json.extract! pickup, :id, :provider, :status, :created_at, :address, :schedule, :route
json.shipments pickup.package_ids
json.manifest pickup.manifest
