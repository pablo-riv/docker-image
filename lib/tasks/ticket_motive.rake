namespace :ticket_motive do
  MOTIVES = [
    { id: 1, subject: 'Consulta sobre creación de envíos en plataforma', kind: 'Ticket' },
    { id: 2, subject: 'Consulta sobre un retiro', kind: 'Ticket', extra: true },
    { id: 3, subject: 'Reportar un problema con un retiro', kind: 'Ticket', extra: true },
    { id: 4, subject: 'Solicitar acción sobre un envío en curso', kind: 'Ticket', extra: true },
    { id: 5, subject: 'Reportar un problema con un envío en curso', kind: 'Ticket', extra: true },
    { id: 6, subject: 'Consulta sobre mi cuenta', kind: 'Ticket' },
    { id: 7, subject: 'Consulta sobre tarifas y cobros', kind: 'Ticket' },
    { id: 8, subject: 'Problemas en autogestión', kind: 'Incidence' }
  ].freeze

  desc 'Create ticket motives'
  task create: :environment do
    TicketMotive.delete_all
    MOTIVES.each { |ticket_motive| TicketMotive.create(ticket_motive) }
  end
end
