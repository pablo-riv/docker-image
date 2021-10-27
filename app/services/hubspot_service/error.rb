module HubspotService
  module Error
    class HubspotError < ::StandardError; end
    class FailedAtFindEmailShipit < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No encontramos el correo de la cuenta?')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class FailedAtFindContact < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No encontramos el contacto en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class FailedAtCreateContact < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No se pudo crear el contacto en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class FailedAtUpdateContact < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No se pudo actualizar el contacto en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class FailedAtFindCompany < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No encontramos la companía en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class FailedAtCreateCompany < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No se pudo crear la compañia en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{mgs} #{error_name}")
      end
    end

    class FailedAtUpdateCompany < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No se pudo actualizar la compañia en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{mgs} #{error_name}")
      end
    end

    class FailureContactAssociation < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No se pudo asociar el contacto en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class FailureCompanyAssociation < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'No se pudo asociar la compaía en hubspot')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end

    class NotImplemented < HubspotError
      attr_accessor :error_name, :company_name
      def initialize(company_name: '', error_name: '', msg: 'metodo no implementado')
        Slack::Hubspot.new&.alert(message: "Cliente #{company_name} #{msg} #{error_name}")
        super("#{msg} #{error_name}")
      end
    end
  end
end