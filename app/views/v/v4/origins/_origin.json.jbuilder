json.extract! origin, :id, :name
json.address_book do
  json.full_name origin.address_book.full_name
  json.phone origin.address_book.phone
  json.email origin.address_book.email
  json.default origin.address_book.default
  json.addressable_type origin.address_book.addressable_type
  json.addressable_id origin.address_book.addressable_id
  address = origin.address_book.address
  json.address do
    json.street address.street
    json.number address.number
    json.complement address.complement
    json.commune_id address.commune_id
    json.commune_name address.commune.name
  end
end
