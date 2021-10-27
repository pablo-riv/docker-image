BooticClient.configure do |c|
  c.client_id = Rails.configuration.bootic[:client_id]
  c.client_secret = Rails.configuration.bootic[:client_secret]
  c.logging = true
end
