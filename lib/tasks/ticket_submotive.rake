namespace :ticket_submotive do
  SUBMOTIVES = [
    { ticket_motive_id: 1, subject: 'Tengo un error al ingresar información manual' },
    { ticket_motive_id: 1, subject: 'Tengo un error al ingresar información a través de planilla (Excel - GSheets)' },
    { ticket_motive_id: 1, subject: 'No se visualizan los envíos en plataforma (integración)' },
    { ticket_motive_id: 1, subject: 'No se visualizan las ventas (integración)' },
    { ticket_motive_id: 1, subject: 'Envío no tiene tracking/courier' },

    { ticket_motive_id: 2, subject: 'Quiero saber cuándo retirarán' },
    { ticket_motive_id: 2, subject: 'Quiero cambiar la dirección de retiro' },
    { ticket_motive_id: 2, subject: 'Quiero cancelar un retiro' },
    { ticket_motive_id: 2, subject: 'Necesito reagendar un retiro' },
    { ticket_motive_id: 2, subject: 'Necesito un retiro más grande de lo habitual' },
    { ticket_motive_id: 2, subject: 'Necesito el retiro de un paquete XL (+60cm)' },

    { ticket_motive_id: 3, subject: 'No puedo imprimir la etiqueta' },
    { ticket_motive_id: 3, subject: 'No cuadra la información de retiro del héroe' },
    { ticket_motive_id: 3, subject: 'No se realizó un retiro solicitado' },
    { ticket_motive_id: 3, subject: 'Capacidad de retiro fue insuficiente' },
    { ticket_motive_id: 3, subject: 'Tengo dudas sobre una multa' },
    { ticket_motive_id: 3, subject: 'Envío retirado sin número de seguimiento' },

    { ticket_motive_id: 4, subject: 'Gestionar un envío devuelto' },
    { ticket_motive_id: 4, subject: 'Quiero cancelar un envío en curso' },
    { ticket_motive_id: 4, subject: 'Eliminar envío' },
    { ticket_motive_id: 4, subject: 'Cambiar la información de envío' },
    { ticket_motive_id: 4, subject: 'Envío sin movimiento o atrasado' },
    { ticket_motive_id: 4, subject: 'Shipit recibió una devolución y necesito reenviar' },
    { ticket_motive_id: 4, subject: 'Envío quedó en sucursal cuando iba a domicilio' },

    { ticket_motive_id: 5, subject: 'Destinatario desconoce la recepción del paquete' },
    { ticket_motive_id: 5, subject: 'Envío llegó incompleto' },
    { ticket_motive_id: 5, subject: 'Notificar un envío dañado' },
    { ticket_motive_id: 5, subject: 'Llegó otro envío al destinatario' },

    { ticket_motive_id: 6, subject: 'Tengo dudas sobre app/plataforma' },
    { ticket_motive_id: 6, subject: 'Tengo dudas sobre mi integración' },
    { ticket_motive_id: 6, subject: 'Quiero contactarme con mi ejecutivo comercial' },
    { ticket_motive_id: 6, subject: 'Necesito cambiar la dirección de mis devoluciones' },
    { ticket_motive_id: 6, subject: 'Otro motivo' },

    { ticket_motive_id: 7, subject: 'Tengo dudas sobre las tarifas' },
    { ticket_motive_id: 7, subject: 'Tengo dudas sobre un cobro realizado' },
    { ticket_motive_id: 7, subject: 'Tengo dudas sobre el seguro adicional' },
    { ticket_motive_id: 7, subject: 'Tengo dudas sobre la facturación' },
    { ticket_motive_id: 7, subject: 'Tengo dudas sobre reembolsos' },

    { ticket_motive_id: 8, subject: 'No puedo enviar los datos o no me ha llegado la confirmación de los cambios' },
    { ticket_motive_id: 8, subject: 'No puedo ingresar ningún dato' },
    { ticket_motive_id: 8, subject: 'No puedo cargar/adjuntar un archivo' },
    { ticket_motive_id: 8, subject: 'No puedo seleccionar items en la lista desplegable' },
    { ticket_motive_id: 8, subject: 'Otro motivo' },
    { ticket_motive_id: 8, subject: 'Ingresé información errónea' }
  ].freeze
  desc 'Create ticket submotives'
  task create: :environment do
    TicketSubmotive.delete_all
    SUBMOTIVES.each { |ticket_submotive| TicketSubmotive.create(ticket_submotive) }
  end
end
