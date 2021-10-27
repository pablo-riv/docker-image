module BsaleConnection
  extend ActiveSupport::Concern
  included do
    def download_bsale(setting)
      bsale = BsaleService.new(@client_id, @client_secret)
      response = bsale.orders
      return if response.blank?
      response['items'].each do |element|
        document = bsale.document(element['guide']['id'])
        client = document['client'].blank? ? {} : bsale.client(document['client']['id'])
        to_hash(element, document, client, setting.company_id)
      end
    end

    def to_hash(element, document, client, company_id)
      new_hash_element = hash_format(element)
      new_hash_document = hash_format(document)
      new_hash_client = hash_format(client)
      new_hash_element[:order_id] = new_hash_element.delete :id
      # waiting for more endpoint information
      new_hash_element.merge!(company_id: company_id, seller: 'bsale', status: 'pending',
                              document: new_hash_document, client: new_hash_client)
      find_or_create_order(new_hash_element)
    end
  end
end
