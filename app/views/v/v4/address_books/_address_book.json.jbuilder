json.extract! address_book, :id, :full_name, :phone, :default, :email, :addressable_type, :addressable_id, :company_id, :created_at, :updated_at
json.name address_book.addressable.name
json.address do
  json.street address_book.address.street
  json.number address_book.address.number
  json.complement address_book.address.complement
  json.commune_id address_book.address.commune_id
  json.zip_code address_book.address.zip_code
  json.commune_name address_book.address.commune.name
end
