module Zendesk
  class Tag
    def initialize(attributes = {})
      @attributes = attributes
    end

    def lost_parcel
      %i[reminder_1 seguimiento_proactivo
         courier_campo reembolso autogestión_reembolso]
    end

    def wrong_address
      %i[reminder_1 seguimiento_proactivo
         courier_campo cambio_dirección autogestión_cambio_dirección]
    end

    def change_address_with_courier
      [
        'reminder_1', 'mvp_3_courier_notified', 'cambio_de_información_pedido',
        'courier_campo', @attributes['courier_for_client']
      ] + values_changed.map { |value| "mvp_3_changed_#{value}" }
    end

    def change_address_with_client
      [
        'reminder_1', 'mvp_3_client_notified', 'cambio_de_información_pedido',
        'cliente_shipit', @attributes['courier_for_client']
      ] + values_changed.map { |value| "mvp_3_changed_#{value}" }
    end

    def values_changed
      @attributes['old'].map do |key, value|
        key unless value == @attributes['new'][key]
      end.compact
    end
  end
end
