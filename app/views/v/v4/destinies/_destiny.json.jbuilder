json.extract! destiny, :id, :name
json.address_book do
  json.full_name destiny.address_book.full_name
  json.phone destiny.address_book.phone
  json.email destiny.address_book.email
  json.default destiny.address_book.default
  json.addressable_type destiny.address_book.addressable_type
  json.addressable_id destiny.address_book.addressable_id
  address = destiny.address_book.address
  json.address do
    json.street address.street
    json.number address.number
    json.complement address.complement
    json.commune_id address.commune_id
    json.commune_name address.commune.name
  end
end
