class CreatePackages < ActiveRecord::Migration[5.0]
  def change
    create_table :packages do |t|
      t.references :commune, foreign_key: true
      t.references :branch_office, foreign_key: true
      t.integer :pickup_id
      t.string :full_name
      t.string :email
      t.string :cellphone
      t.float :length
      t.float :width
      t.float :height
      t.float :weight
      t.string :approx_size
      t.float :volume_price
      t.string :reference
      t.boolean :is_payable
      t.boolean :is_fragile
      t.boolean :is_wrapper_paper
      t.boolean :is_recheabe
      t.boolean :is_printed
      t.boolean :is_paid_shipit
      t.boolean :is_returned
      t.boolean :is_available
      t.boolean :is_archive
      t.boolean :is_exception
      t.boolean :is_mail_to_receiver
      t.string :courier_for_entity
      t.string :courier_type
      t.string :courier_for_client
      t.text :comments
      t.text :reason
      t.string :serial_number
      t.integer :items_count
      t.string :product_type
      t.datetime :shipping_type
      t.string :tracking_number
      t.float :shipping_price
      t.string :material_extra
      t.float :total_price
      t.string :shipit_code
      t.float :shipping_cost
      t.string :trello_item
      t.string :parent_ot
      t.string :has_ot
      t.string :box_type
      t.string :packing
      t.string :sell_type
      t.string :sku_supplier
      t.string :supplier_name
      t.string :craftman_state
      t.string :voucher_price
      t.float :pickup_distance
      t.string :kind_of_order

      t.timestamps
    end
  end
end
