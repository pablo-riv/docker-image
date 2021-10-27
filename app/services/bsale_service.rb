class BsaleService
  def initialize(client_id, secret)
    puts "secret: #{secret}".yellow
    @bsale = BsaleApi.new(secret)
  end

  def orders
    @bsale.shippings
  end

  def document(document_id)
    @bsale.document({ method: 'GET', specific: "/#{document_id}" })
  end

  def document(client_id)
    @bsale.client({ method: 'GET', specific: "/#{client_id}" })
  end
end
