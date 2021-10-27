module Zendesk
  module Requester
    def extract_requester_type
      case requester
      when 'courier' then 0
      when 'cliente_shipit' then 1
      when 'destinatario_final' then 2
      when 'kam' then 3
      when 'bodeka_kw_kp' then 4
      when 'otros_proveedores' then 5
      else 7
      end
    rescue StandardError => _e
      6
    end

    private

    def requester
      support[:requester_type].try(:downcase) || support[:custom_fields].select { |cf| cf[:id] == 360030457754 }.first[:value]
    end
  end
end
