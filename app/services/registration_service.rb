class RegistrationService
  attr_accessor :attributes, :errors, :company, :account, :person
  def initialize(attributes)
    @attributes = attributes
    @errors = []
  end

  def create
    validate_properties
    raise @errors.pop unless @errors.size.zero?

    object = @attributes[:has_hubspot_contact] ? object_from_hubspot : object_from_suite
    create_company(object[:company])
    raise @errors.pop unless @errors.size.zero?

    create_person(object[:person])
    create_account(object[:account])
    update_address
    raise @errors.pop unless @errors.size.zero?

    @account
  end

  def account_object
    @attributes[:has_hubspot_contact] ? object_from_hubspot : object_from_suite
  end

  private

  def validate_properties
    @errors << "El cliente #{@attributes[:suite][:company_name]} ya existe" if Entity.companies.where('LOWER(name) = ?', @attributes[:suite][:company_name].try(:downcase)).present?
    @errors << 'El Email ingresado ya esta siendo utilizado.. Ingrese otro por favor' if Account.where(email: @attributes[:suite][:email]).count.positive?
  end

  def object_from_hubspot
    {
      account: {
        email: @attributes[:suite][:email],
        password: @attributes[:suite][:password],
        password_confirmation: @attributes[:suite][:password_confirmation],
        how_to_know_shipit: @attributes[:suite][:how_to_know_shipit]
      },
      person: {
        first_name: contact[:firstname],
        last_name: contact[:lastname],
        phone: contact[:phone]
      },
      company: {
        name: @attributes[:suite][:company_name],
        reference_to_name: "#{@attributes[:suite][:email]}_#{@attributes[:suite][:company_name]}",
        capture: @attributes[:suite][:company_capture],
        first_owner_id: salesman.try(:id) || 14,
        second_owner_id: salesman.try(:id) || 14,
        sales_channel: { names: [], categories: [] },
        definition: contact[:description],
        package_monthly_range: contact[:cantidad_de_env_os_mensuales_esperados],
        hubspot_contact_id: contact[:hs_object_id],
        hubspot_company_id: '',
        website: contact[:website],
        run: '',
        phone: contact[:phone],
        email_notification: @attributes[:suite][:email],
        business_turn: '',
        business_name: '',
        bill_email: '',
        bill_phone: '',
        bill_address: '',
        contact_name: "#{contact[:firstname]} #{contact[:lastname]}",
        email_contact: contact[:email_contact],
        platform_version: 3,
        term_of_service: true,
        know_size_restriction: true,
        know_base_charge: true,
        partner_id: partner.try(:id)
      },
      branch_office: {
        contact_name: "#{contact[:firstname]} #{contact[:lastname]}",
        phone: contact[:phone]
      }
    }
  end

  def object_from_suite
    {
      account: {
        email: @attributes[:suite][:email],
        password: @attributes[:suite][:password],
        password_confirmation: @attributes[:suite][:password_confirmation],
        how_to_know_shipit: @attributes[:suite][:how_to_know_shipit]
      },
      person: {
        first_name: @attributes[:suite][:first_name],
        last_name: @attributes[:suite][:last_name],
        phone: @attributes[:suite][:phone]
      },
      company: {
        name: @attributes[:suite][:company_name],
        reference_to_name: "#{@attributes[:suite][:email]}_#{@attributes[:suite][:company_name]}",
        capture: @attributes[:suite][:company_capture],
        first_owner_id: salesman.try(:id) || 14,
        second_owner_id: salesman.try(:id) || 14,
        sales_channel: { names: [], categories: [] },
        definition: @attributes[:suite][:company_description],
        package_monthly_range: @attributes[:suite][:quantity],
        platform_version: 3,
        term_of_service: true,
        know_size_restriction: true,
        know_base_charge: true,
        partner_id: partner.try(:id)
      }
    }
  end

  def contact
    @attributes[:contact]
  end

  def partner
    @attributes[:partner]
  end

  def create_account(data)
    Account.transaction do
      @account = Account.new(data)
      raise ActiveRecord::Rollback unless @account.password == @account.password_confirmation

      @account.entity_id = @company.acting_as.id
      @account.person_id = @person.id
      @errors << ActiveRecord::Rollback unless @account.save(validate: false)
      @errors << ActiveRecord::Rollback unless @account.persisted?
      @account.add_role(:commercial)
    end
  end

  def create_company(data)
    Company.transaction do
      @company = Company.new(data)
      @errors << ActiveRecord::Rollback unless @company.save(validate: false)
      @company.generate_relation
    end
  rescue => e
    @errors << "El cliente #{data[:name]} ya existe"
  end

  def create_person(data)
    Person.transaction do
      @person = Person.create(data)
      @errors << ActiveRecord::Rollback unless @person.save(validate: false)
    end
  end

  def update_address
    commune =
      if @attributes[:suite][:commune_id].present?
        Commune.where(id: @attributes[:suite][:commune_id])
      elsif
        Commune.where('LOWER(name) LIKE ?', "%#{contact['comuna2'].try(:downcase)}%")
      end
    @company.address.update_columns(commune_id: commune.first.try(:id))
  end

  def salesman
    Salesman.find_by(email: @attributes[:suite][:seller_email])
  end
end
