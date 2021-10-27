module Packable
  extend Apipie::DSL::Concern

  def_param_group :pack do
    param :package, Hash, action_aware: true, required: true do
      param :commune_id, Integer, required: true
      param :branch_office_id, Integer, required: true
      param :pickup_id, Integer, required: true
      param :full_name, String, required: true
      param :email, String, required: true
      param :cellphone, String
      param :length, Float
      param :width, Float
      param :height, Float
      param :weight, Float
      param :approx_size, String
      param :volume_price, Float
      param :reference, String
      param :is_payable, :boolean, required: true
      param :is_fragile, :boolean, required: true
      param :is_wrapper_paper, :boolean, required: true
      param :is_reachable, :boolean, required: true
      param :is_printed, :boolean, required: true
      param :is_paid_shipit, :boolean, required: true
      param :is_returned, :boolean, required: true
      param :is_available, :boolean, required: true
      param :is_archive, :boolean, required: true
      param :is_exception, :boolean, required: true
      param :is_mail_to_receiver, :boolean, required: true
      param :courier_for_entity, String, required: true
      param :courier_type, String
      param :courier_for_client, String
      param :comments, String
      param :reason, String
      param :serial_number, String
      param :items_count, Integer
      param :product_type, String
      param :tracking_number, String
      param :shipping_price, Float
      param :material_extra, String
      param :total_price, Float
      param :shipit_code, String
      param :shipping_cost, Float
      param :trello_item, String
      param :parent_ot, String
      param :has_ot, String
      param :box_type, String
      param :packing, String
      param :sell_type, String
      param :sku_supplier, String
      param :supplier_name, String
      param :craftman_state, String
      param :voucher_price, String
      param :pickup_distance, Float
      param :kind_of_order, String
      param :address_attributes, Hash do
         param :commune_id, Integer, required: true
         param :complement, String, required: true
         param :number, Integer, required: true
         param :street, String, required: true
         param :coords, Hash, required: true do
           param :latitude, Float, required: true
           param :longitude, Float, required: true
         end
       end
      param :inventory_activity, Hash do
        param :description, String
        param :inventory_activity_order_attributes, Hash do
          param :sku_id, Integer
          param :amount, Float
        end
      end
    end
  end
end
