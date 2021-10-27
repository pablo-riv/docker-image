json.extract! order.decorate, :id, :platform, :kind, :reference, :items, :sandbox, :company_id, :service,
                              :state, :products, :payable, :payment, :source, :seller, :gift_card, :sizes,
                              :courier, :prices, :insurance, :state_track, :origin, :destiny,
                              :created_at, :updated_at, :commune_name

json.valid order.origin_valid? && order.destiny_valid? && order.sizes_valid?
json.ready_to_ship do
  json.origin order.origin_valid?
  json.destiny order.destiny_valid?
  json.sizes order.sizes_valid?
  json.courier true
end
