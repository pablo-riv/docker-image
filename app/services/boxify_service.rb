class BoxifyService
  include HTTParty
  base_uri Rails.configuration.boxify_endpoint

  attr_accessor :shipments
  def initialize(shipments)
    @shipments = shipments
    @headers = {
      'Content-Type' => 'application/json'
    }
  end

  def calculate
    response = self.class.post('/packs', { headers: @headers, body: @shipments.to_json, verify: false })
    raise 'No pudimos calcular las medidas para los productos ingresados' unless (200..204).cover?(response.code)

    response['packing_measures'].with_indifferent_access
  rescue => e
    Slack::Ti.new({}, {}).alert('', "NO SE PUDO OBTENER MEDIDAS DE LOS PRODUCTOS\nSYSTEM ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
    { width: 10, height: 10, length: 10, weight: 1 }.with_indifferent_access
  end
end
