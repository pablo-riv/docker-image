module Zendesk
  class Message
    def initialize(attributes = {}, agent_name = '')
      @attributes = attributes
      @agent_name = agent_name
    end

    def lost_parcel
      "Hola #{@agent_name},
      <br><br>
      Adjunto documentos para empezar el proceso de indemnización del " \
      "envío #{@attributes['tracking_number']}.
      <br><br>
      Favor acusar recibo.
      <br><br>
      Saludos!
      <br><br>"
    end

    def wrong_address
      "Hola #{@agent_name},
      <br><br>
      Hemos detectado un error con la dirección para el " \
      "envío #{@attributes['tracking_number']} y solicitamos " \
      "modificar por la entregada a continuación.
      <br><br>
      <strong>Nueva información de entrega:</strong><br><br>
      #{format_values_changed}<br>
      Gracias y saludos.<br>"
    end

    def change_address_with_client
      "Hola,<br><br>
      Recibimos tu solicitud de cambio de información del envío " \
      "<i>#{@attributes['reference']}</i> y <b>ya enviamos " \
      "la nueva información</b> al courier.<br><br>
      Te recordamos que:<br><br>
      <ul>
      <li>El cambio de información puede atrasar la entrega del producto " \
      "hasta <b>96 horas hábiles</b>.</li>
      <li>Si hay un cambio de comuna, el costo de envío puede aumentar " \
      "o se te puede cobrar un nuevo envío.</li>
      <li>La empresa de despacho puede <b>no realizar esta gestión</b> y " \
      "devolver tu producto a origen.</li>
      </ul>
      <br>
      Gracias por tu comprensión,<br>"
    end

    def change_address_with_courier
      changed_values = format_values_changed
      text = "Hola #{@agent_name} <br><br>"
      text += if changed_values != ''
                'Solicito cambio de dirección para la ' \
                "carga #{@attributes['tracking_number']}" \
                '<br><br>' \
                '<strong>Nueva información de entrega:</strong><br><br>' \
                "#{changed_values}<br>"
              else
                "La información de la carga #{@attributes['tracking_number']}" \
                ' fue validada por el cliente como una dirección válida.<br>'
              end
      text + 'Gracias y saludos.<br>'
    end

    def format_values_changed
      format = ''
      values_changed.each do |value|
        format += '&#9;' + I18n.t("zendesk.attributes.#{value.downcase}")
        format += ": #{@attributes['new'][value]}<br><br>"
      end
      format
    end

    def values_changed
      @attributes['old'].map do |key, value|
        key unless value == @attributes['new'][key]
      end.compact
    end
  end
end
