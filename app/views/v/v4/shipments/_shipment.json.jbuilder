json.extract! shipment, :id, :reference, :branch_office_id, :items_count, :packing, :status, :tracking_number, :courier_status,
                        :destiny, :courier_for_client, :created_at, :updated_at, :is_returned, :total_is_payable,
                        :email, :cellphone, :length, :width, :height, :weight, :is_payable, :billing_date, :shipping_price,
                        :approx_size, :volume_price, :shipping_type, :total_price, :shipit_code, :estimated_delivery,
                        :courier_url, :url_pack, :pack_pdf, :courier_status_updated_at, :shipit_status_updated_at,
                        :purchase, :operation_date, :inventory_activity, :label_printed, :sub_status, :courier_branch_office_id
json.old_ticket_url_courier shipment.courier_url
json.ticket_shipit_url shipment.shipit_ticket_url
json.ticket_url shipment.url_pack
json.ticket_shipit_pdf_url shipment.pack_pdf
json.shipit_tracking_link shipment.courier_tracking_link
json.address shipment.address.try(:serialize_shipment!)
json.overcharge shipment.total_is_payable
json.total shipment.total_price
json.editable shipment.editable_by_client
json.archivable shipment.archivable_by_client
json.returnable shipment.returnable_by_client
json.schedulable shipment.not_retired
json.integration_reference shipment.integration_reference
json.origin origin
json.check_in shipment.check?('in')
json.check_out shipment.check?('out')
json.notifications shipment.alerts_sent
json.whatsapps shipment.whatsapps_sent
json.full_name shipment.decorate.full_name
json.tickets do
  json.quantity shipment.supports.size
  json.last_ticket shipment.supports.last
end
json.order shipment.order
json.insurance shipment.insurance
json.last_pickup shipment.pickups.last
json.estimated_pickup_time shipment.pick_and_pack["estimated_at"]
