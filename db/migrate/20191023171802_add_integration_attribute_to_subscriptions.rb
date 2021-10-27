class AddIntegrationAttributeToSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :integrations, :json, default: { shopify: false,
                                                                bootic: false,
                                                                jumpseller: false,
                                                                vtex: false,
                                                                woocommerce: false,
                                                                prestashop: false }
  end
end
