class AddAuthenticationTokenToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :authentication_token, :string
  end
end
