module OperationalInformation
  class ProactiveMonitoring

    # CLASS METHODS
    def self.by_kind
      CourierOperationalInformation.by_kind
    end

    def self.compose_hash_struct
      struct = {}
      by_kind.each do |information|
        courier_name         = format_name(information.courier.name)
        struct[courier_name] = internal_struct(information)
      end
      struct
    end

    def self.internal_struct(information)
      { spread_values: [],
        email_to: information.main_email,
        cc: information.emails,
        cheer: information.greeting,
        subject: information.shipping_reference }
    end

    def self.format_name(name)
      "#{name.downcase}_xlsx".to_sym
    end
  end
end
