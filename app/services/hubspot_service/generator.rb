module HubspotService
  class Generator
    include HubspotService::Bridge

    attr_accessor :object, :errors
    def initialize(object)
      @object = object
      @errors = []
    end

    def create
      retries = 0
      max_retries = company_max_retries
      emails = company_emails_availables
      begin
        raise company.validate! unless company.valid?
        # query hubspot contact by company emails availables
        hubspot_contact = find_contact_by_email(emails[retries])
        # validate if has more retries
        unless max_retries == retries
          # validate if emails isn't recorded at hubspot and retry
          puts "ERROR: CLIENTE: #{company.name}\n#{hubspot_contact}"
          raise Error::FailedAtFindContact.new(company_name: company.name, error_name: hubspot_contact['errors'].first['message']) if hubspot_contact['status'] == 'error' && emails.size > 1
        end
        # validate if emails is recorded at hubspot and sync contact
        if (200..204).cover?(hubspot_contact.code)
          update_company_contact(hubspot_contact) unless company.hubspot_contact_id.present?
        end

        create_or_update_hubspot_contact

        update_company_contact(hubspot_contact)
        # create or update company on hubspot
        create_or_update_hubspot_company if company.hubspot_contact_id.present?
        # associate company and contact
        raise unless associate

        return company
      rescue => e
        # retry with new retry index
        raise unless e.class == Error::FailedAtFindContact

        retries += 1
        retry if retries < max_retries
      end
    rescue StandardError => e
      puts e.message
    end

    def update
      create_or_update_hubspot_contact
      create_or_update_hubspot_company
    end

    private

    def create_or_update_hubspot_company
      # validate if company is ready exists on hubspot
      company.hubspot_company_id.present? ? update_hubspot_company : create_hubspot_company
    end

    def create_or_update_hubspot_contact
      # validate if contact is ready exists on hubspot
      company.hubspot_contact_id.present? ? update_hubspot_contact : create_hubspot_contact
    end

    def company
      @object[:company]
    end

    def account
      @object[:account]
    end

    def create_hubspot_company
      company_dispatcher = HubspotService::Company.new(company: company, account: account, drop_out: account.drop_outs.last)
      hubspot_company = create_company(company_dispatcher.hubspot_properties)
      raise Error::FailedAtCreateCompany.new(company_name: company.name, error_name: hubspot_company['validationResults'].first['message']) unless hubspot_company['companyId'].present?

      ::Company.transaction do
        company.update(hubspot_company_id: hubspot_company['companyId'])
      end
      hubspot_company['companyId']
    end

    def update_hubspot_company
      company_dispatcher = HubspotService::Company.new(company: company, account: account, drop_out: account.drop_outs.last)
      hubspot_company = update_company(company_dispatcher.hubspot_properties)
      raise Error::FailedAtUpdateCompany.new(company_name: company.name, error_name: hubspot_company['validationResults'].first['message']) unless (200..204).cover?(hubspot_company.code)

      hubspot_contact = find_contact_by_email(account.email)
      return hubspot_company unless hubspot_contact['properties'].try('nps_score').present?

      begin
        company.update(nps_score: hubspot_contact['properties']['nps_score']['value'].to_i)
      rescue => exception
        puts "Can't update nps\nError: #{exception.message}\n#{exception.backtrace[0]}".red.swap
      end
      hubspot_company
    end

    def create_hubspot_contact
      contact_dispatcher = HubspotService::Contact.new(company: company, account: account)
      hubspot_contact = create_contact(contact_dispatcher.hubspot_properties)

      unless hubspot_contact['vid'].present?
        message = hubspot_contact['validationResults'].first['message'].length >= 2400 ? hubspot_contact['validationResults'].first['message'][0..44] : hubspot_contact['validationResults'].first['message']
        raise Error::FailedAtCreateContact.new(company_name: company.name, error_name: message)
      end

      update_company_contact(hubspot_contact)
    end

    def update_hubspot_contact
      contact_dispatcher = HubspotService::Contact.new(company: company, account: account)
      hubspot_contact = update_contact(contact_dispatcher.hubspot_properties)
      raise Error::FailedAtCreateContact.new(company_name: company.name, error_name: hubspot_contact['validationResults'].pluck('message').join('\n')) unless (200..204).cover?(hubspot_contact.code)

      hubspot_contact
    end

    def associate
      create_hubspot_association
      associate_company_to_contact
    end

    def create_hubspot_association
      contact_associated = associate_contact_to_company
      raise Error::FailureContactAssociation.new(company_name: company.name, error_name: contact_associated['validationResults'].first['message']) if contact_associated['status'].present? && contact_associated['status'] == 'error'

      company_associated = associate_company_to_contact
      raise Error::FailureCompanyAssociation.new(company_name: company.name, error_name: contact_associated['validationResults'].first['message']) if company_associated['status'].present? && company_associated['status'] == 'error'
    end

    def update_company_contact(contact)
      ::Company.transaction do
        company.update(hubspot_contact_id: contact['vid'])
      end
      company.persisted?
    end

    def company_max_retries
      # total email contact addded and account email
      return 1 unless company.email_contact.present?

      company.email_contact.split(',').length + 1
    end

    def company_emails_availables
      # collect all emails of company
      emails = [account.email]
      return emails unless company.email_contact.present?

      emails.concat(company.email_contact.gsub(' ', '').split(','))
    rescue => e
      Error::FailedAtFindEmailShipit.new(company_name: company.name, error_name: "#{company.name} #{e.message}")
      puts e.message
    end
  end
end
