json.extract! shipment, :id, :reference, :full_name, :in_created_at, :return_created_at,
                        :automatic_retry_date, :comments, :created_at, :status, :company_name,
                        :height, :width, :length, :weight, :tracking_number, :courier_for_client,
                        :is_returned, :branch_office_id, :cellphone, :items_count, :volume_price,
                        :approx_size

json.address do
  json.street shipment.address_street
  json.number shipment.address_number
  json.complement shipment.address_complement
  json.commune_id shipment.address_commune_id
end
json.origin origin
