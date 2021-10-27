require 'faker'

FactoryBot.define do
  factory :pickup do
    provider { 1 }
    status { 0 }
    type_of_pickup { 1 }
    archive { false }
    schedule { { 'date': '', 'range_time': '', 'active': false } }
    address { { 'place': '', 'coords': { 'lat': 0, 'lng': 0 } } }
    route { 'MyString' }
    branch_office_id { SecureRandom.uuid }
    driver { { 'email': '', 'name': '', 'document_id': '', 'vehicle_plate': '', 'courier_driver_id': ''} }
    pickup_uuid { SecureRandom.uuid }
    manifest_uuid { SecureRandom.uuid }
    origin_id { 0 }
  end
end
