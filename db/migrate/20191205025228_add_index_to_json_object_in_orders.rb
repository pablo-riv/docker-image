class AddIndexToJsonObjectInOrders < ActiveRecord::Migration[5.0]
  def self.up
    execute <<-SQL
      CREATE INDEX index_orders_on_destiny_street ON orders ((destiny ->> 'street'));
      CREATE INDEX index_orders_on_destiny_number ON orders ((destiny ->> 'number'));
      CREATE INDEX index_orders_on_destiny_commune_id ON orders ((destiny ->> 'commune_id'));
      CREATE INDEX index_orders_on_destiny_full_name ON orders ((destiny ->> 'full_name'));
      CREATE INDEX index_orders_on_destiny_phone ON orders ((destiny ->> 'phone'));
      CREATE INDEX index_orders_on_destiny_email ON orders ((destiny ->> 'email'));
      CREATE INDEX index_orders_on_destiny_courier_branch_office_id ON orders ((destiny ->> 'courier_branch_office_id'));
      CREATE INDEX index_orders_on_destiny_kind ON orders ((destiny ->> 'kind'));

      CREATE INDEX index_orders_on_origins_street ON orders ((origin ->> 'street'));
      CREATE INDEX index_orders_on_origins_number ON orders ((origin ->> 'number'));
      CREATE INDEX index_orders_on_origins_commune_id ON orders ((origin ->> 'commune_id'));
      CREATE INDEX index_orders_on_origins_full_name ON orders ((origin ->> 'full_name'));
      CREATE INDEX index_orders_on_origins_phone ON orders ((origin ->> 'phone'));
      CREATE INDEX index_orders_on_origins_email ON orders ((origin ->> 'email'));

      CREATE INDEX index_orders_on_sizes_width ON orders ((sizes ->> 'width'));
      CREATE INDEX index_orders_on_sizes_height ON orders ((sizes ->> 'height'));
      CREATE INDEX index_orders_on_sizes_length ON orders ((sizes ->> 'length'));
      CREATE INDEX index_orders_on_sizes_weight ON orders ((sizes ->> 'weight'));

      CREATE INDEX index_orders_on_courier_client ON orders ((courier ->> 'client'));
      CREATE INDEX index_orders_on_courier_entity ON orders ((courier ->> 'entity'));
      CREATE INDEX index_orders_on_courier_tracking ON orders ((courier ->> 'tracking'));
      CREATE INDEX index_orders_on_courier_payable ON orders ((courier ->> 'payable'));

      CREATE INDEX index_orders_on_seller_name ON orders ((seller ->> 'name'));
    SQL

    add_index :orders, :reference
    add_index :orders, :service
  end

  def self.down
    execute <<-SQL
      DROP INDEX index_orders_on_destiny_street;
      DROP INDEX index_orders_on_destiny_number;
      DROP INDEX index_orders_on_destiny_commune_id;
      DROP INDEX index_orders_on_destiny_full_name;
      DROP INDEX index_orders_on_destiny_phone;
      DROP INDEX index_orders_on_destiny_email;
      DROP INDEX index_orders_on_destiny_courier_branch_office_id;
      DROP INDEX index_orders_on_destiny_kind;

      DROP INDEX index_orders_on_origins_street;
      DROP INDEX index_orders_on_origins_number;
      DROP INDEX index_orders_on_origins_commune_id;
      DROP INDEX index_orders_on_origins_full_name;
      DROP INDEX index_orders_on_origins_phone;
      DROP INDEX index_orders_on_origins_email;

      DROP INDEX index_orders_on_sizes_width;
      DROP INDEX index_orders_on_sizes_height;
      DROP INDEX index_orders_on_sizes_length;
      DROP INDEX index_orders_on_sizes_weight;

      DROP INDEX index_orders_on_courier_client;
      DROP INDEX index_orders_on_courier_entity;
      DROP INDEX index_orders_on_courier_tracking;
      DROP INDEX index_orders_on_courier_payable;
      DROP INDEX index_orders_on_seller_name;
    SQL

    remove_index :orders, :reference
    remove_index :orders, :service
  end
end
