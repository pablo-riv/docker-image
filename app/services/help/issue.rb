module Help
  class Issue
    TYPES = %w(problem incident question)
    attr_accessor :properties, :priority

    def initialize(properties)
      @properties = properties
      @type = Category.new(subject, other_subject)
      @priority = Priority.new(kind: type,
                               category: company.category,
                               commercial_priority: company.priority,
                               packages_hope: company.packages_hope,
                               last_month_deliveries: company.last_month_deliveries)
    end

    def assign
      # case priority
      # when 'low', 'normal' then 'macarena@shipit.cl' # needs agent ID
      # when 'high', 'urgent' then 'carolina@shipit.cl' # needs agent ID
      # else
      #   'hola@shipit.cl' # 3099134408
      # end
      3099134408 # ID hola@shipit.cl
    end

    def type
      categorize
    end

    def package
      properties[:package]
    end

    def subject
      properties[:subject]
    end

    def other_subject
      properties[:other_subject]
    end

    def message
      properties[:message]
    end

    def priority
      priorize
    end

    def account
      properties[:account]
    end

    def zendesk_id
      properties[:account].zendesk_id
    end

    def internal_id
      properties[:internal_id]
    end

    def provider_id
      properties[:provider_id]
    end

    def company
      properties[:company]
    end

    def requester_type
      case properties[:requester_type].downcase
      when 'shipit_client' then 'cliente_shipit'
      when 'courier' then 'courier'
      when 'final_recipient' then 'destinatario_final'
      when 'kam' then 'kam'
      when 'warehouse' then 'bodeka_kw_kp'
      else 
        properties[:requester_type]
      end
    end

    private

    def priorize
      @priority.priorize
    end

    def categorize
      @type.categorize
    end
  end
end
