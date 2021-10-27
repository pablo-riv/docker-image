Apipie.configure do |config|
  config.app_name                = "ShipitCore"
  config.api_base_url["v2"]      = "/v"
  config.doc_base_url            = "/docs"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/v/**/*.rb"
  config.default_version         = "v2"
  config.validate                = false
  config.layout                  = "layouts/sign_in"
end
