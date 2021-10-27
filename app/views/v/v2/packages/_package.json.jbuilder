json.extract! package, :id, :reference, :full_name, :email, :items_count, :cellphone, :is_payable, :tracking_url,
                       :packing, :shipping_type, :destiny, :courier_for_client, :tracking_number, :seller_order_id,
                       :is_returned, :total_is_payable, :shipping_price, :material_extra, :total_price, :volume_price,
                       :approx_size, :status, :sub_status, :courier_status, :courier_status_updated_at, :length, :width, :height, :weight, :delivery_time, :created_at, :updated_at, :courier_url
json.old_ticket_url_courier package.attributes["courier_url"]
json.ticket_shipit_url package.shipit_ticket_url
json.ticket_url package.url_pack
json.ticket_shipit_pdf_url package.pack_pdf
json.link v_package_url(package)
unless package.address.nil?
  json.address do |json|
    json.street package.address.street
    json.number package.address.number
    json.complement package.address.complement
    json.commune package.address.commune.name
    json.commune_id package.address.commune.id
    json.coords package.address.coords
  end
end
json.inventory_activity package.inventory_activity
json.integration_reference package.integration_reference
