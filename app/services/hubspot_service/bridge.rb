
module HubspotService
  module Bridge
    def self.find_contact_by_email(email)
      HTTParty.get("https://api.hubapi.com/contacts/v1/contact/email/#{email}/profile", { headers: { 'Content-Type' => 'application/json' },
                                                                                          query: { hapikey: Rails.configuration.hubspot_api_key,
                                                                                                   'propertyMode' => 'value_only' },
                                                                                          verify: false })
    end

    def find_contact_by_email(email)
      HTTParty.get("https://api.hubapi.com/contacts/v1/contact/email/#{email}/profile", { headers: { 'Content-Type' => 'application/json' },
                                                                                          query: { hapikey: Rails.configuration.hubspot_api_key,
                                                                                                   'propertyMode' => 'value_only' },
                                                                                          verify: false })
    end

    def find_contact_by_id
      HTTParty.get("https://api.hubapi.com/contacts/v1/contact/email/vid/#{company.hubspot_contact_id}/profile", { headers: { 'Content-Type' => 'application/json' },
                                                                                                                   query: { hapikey: Rails.configuration.hubspot_api_key,
                                                                                                                            'propertyMode' => 'value_only' },
                                                                                                                   verify: false })
    end

    def create_contact(attrs)
      response = HTTParty.post('https://api.hubapi.com/contacts/v1/contact/', { headers: { 'Content-Type' => 'application/json' },
                                                                                query: { hapikey: Rails.configuration.hubspot_api_key },
                                                                                body: attrs.to_json,
                                                                                verify: false })
      response
    end

    def update_contact(attrs)
      response = HTTParty.post("https://api.hubapi.com/contacts/v1/contact/vid/#{company.hubspot_contact_id}/profile", { headers: { 'Content-Type' => 'application/json' },
                                                                                                                         query: { hapikey: Rails.configuration.hubspot_api_key },
                                                                                                                         body: attrs.to_json,
                                                                                                                         verify: false })
      response
    end

    def find_company
      HTTParty.get("https://api.hubapi.com/companies/v2/companies/#{company.hubspot_company_id}", { headers: { 'Content-Type' => 'application/json' },
                                                                                                    query: { hapikey: Rails.configuration.hubspot_api_key,
                                                                                                            'propertyMode' => 'value_only' },
                                                                                                    verify: false})
    end

    def create_company(attrs)
      response = HTTParty.post('https://api.hubapi.com/companies/v2/companies', { headers: { 'Content-Type' => 'application/json' },
                                                                                  query: { hapikey: Rails.configuration.hubspot_api_key },
                                                                                  body: attrs.to_json,
                                                                                  verify: false })
      response
    end

    def update_company(attrs)
      response = HTTParty.put("https://api.hubapi.com/companies/v2/companies/#{company.hubspot_company_id}", { headers: { 'Content-Type' => 'application/json' },
                                                                                                               query: { hapikey: Rails.configuration.hubspot_api_key },
                                                                                                               body: attrs.to_json,
                                                                                                               verify: false })
      response
    end

    def associate_company_to_contact
      HTTParty.put('https://api.hubapi.com/crm-associations/v1/associations', { headers: { 'Content-Type' => 'application/json' },
                                                                                query: { hapikey: Rails.configuration.hubspot_api_key },
                                                                                body: { 'fromObjectId' => company.hubspot_company_id,
                                                                                        'toObjectId' => company.hubspot_contact_id,
                                                                                        'category' => 'HUBSPOT_DEFINED',
                                                                                        'definitionId' => 2 }.to_json,
                                                                                verify: false })
    end

    def associate_contact_to_company
      HTTParty.put('https://api.hubapi.com/crm-associations/v1/associations', { headers: { 'Content-Type' => 'application/json' },
                                                                                query: { hapikey: Rails.configuration.hubspot_api_key },
                                                                                body: { 'fromObjectId' => company.hubspot_contact_id,
                                                                                        'toObjectId' => company.hubspot_company_id,
                                                                                        'category' => 'HUBSPOT_DEFINED',
                                                                                       'definitionId' => 1 }.to_json,
                                                                                verify: false })
    end
  end
end
