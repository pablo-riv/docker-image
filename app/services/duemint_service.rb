class DuemintService
  include HTTParty
  base_uri 'https://api.duemint.com/v1/'

  def initialize
    @headers = {
      'Authorization' => "Bearer #{Rails.configuration.duemint[:api_token]}",
      'Accept' => 'application/json'
    }
  end

  def clients(page: 1)
    response = self.class.get('/getClients', { headers: @headers, query: { 'expandContact' => 1, 'resultsPerPage' => 100, 'page' => page }, verify: false })
    raise response.message unless response.success?

    HashWithIndifferentAccess.new(response)
  end

  def get_documents(duemint_id: nil, page: 1, from_date: (Date.current.at_beginning_of_month - 1.month).strftime('%Y-%m-%d'))
    response = self.class.get('/getDocuments', { verify: false,
                                                 headers: @headers,
                                                 query: { 'dateBy' => from_date,
                                                          'page' => page,
                                                          'clientId': duemint_id,
                                                          'expandClient' => 1,
                                                          'resultsPerPage' => 100 } })
    raise response.message unless response.success?

    HashWithIndifferentAccess.new(response)
  rescue StandardError => e
    Rails.logger.info e.message.red.swap
  end

  def document_by_client(duemint_reference: nil)
    response = self.class.get('/getDocument', { headers: @headers, query: { id: duemint_reference }, verify: false })
    raise response.message unless response.success?

    HashWithIndifferentAccess.new(response)
  rescue StandardError => e
    Rails.logger.info e.message.red.swap
    {}
  end

  def download(companies = [])
    companies.find_each(batch_size: 10).each do |company|
      begin
        documents = get_documents_by_company(company)
        unless documents.present?
          puts "CLIENTE: #{company.name} no tiene facturas".yellow.swap
          next
        end

        documents.each { |monthly_invoice| process_document(monthly_invoice, company) }
      rescue StandardError => e
        Rails.logger.info e.message.red.swap
      end
    end
  end

  def get_documents_by_company(company)
    documents = []
    duemint_data =
      get_documents(duemint_id: company.duemint_id,
                    page: 1,
                    from_date: (Date.current - 3.month).strftime('%Y-%m-%d'))
    total_pages = duemint_data.dig(:records, :pages).to_i
    puts "#{total_pages} PÁGINAS PARA LA COMPAÑÍA: #{company.name} ".yellow.swap
    documents += 1.upto(total_pages).map do |page|
      response = get_documents(duemint_id: company.duemint_id,
                               page: (page.zero? ? 1 : page),
                               from_date: Date.current.strftime('%Y-%m-%d'))
      response.present? ? response[:items] : []
    end
    documents.flatten
  end

  def process_document(document, company)
    return unless [document, company].all?(&:present?)

    notes_data = sanitized_document_gloss(document['notes'])
    emit_date = notes_data[:emit_date].presence || document['issueDate'].to_date.at_beginning_of_month
    emit_date -= 1.month if emit_date < Date.new(2020, 12)

    invoice = Invoice.find_by(duemint_reference: document['id'])
    company = Company.find_by(id: notes_data[:company_id]) if notes_data[:company_id].to_i.positive?
    invoice = company.invoices.find_or_create_by(emit_date: emit_date) unless invoice.present?
    return puts "FACTURA #{invoice.duemint_reference} PAGADA".cyan if invoice.completed?

    update_invoice_data(invoice, document)
  end

  def document_state(status)
    case status
    when 1 then :paid
    when 2 then :expired_soon
    when 3 then :expired
    when 4 then :to_cancel
    else
      status.present? ? :created : :no_emited
    end
  end

  def update_invoice_data(invoice, document)
    invoice.update(duemint_reference: document['id'],
                   paid_amount: document['paidAmount'],
                   paid_date: document['paidDate'],
                   taxes: document['taxes'],
                   net: document['net'],
                   notes: document['notes'],
                   gloss: document['gloss'],
                   due_date: document['dueDate'],
                   number: document['number'],
                   state: document_state(document['status']),
                   files: { pdf: document['pdf'],
                            xml: document['xml'],
                            url: document['url'] })
    puts "Factura ID: #{invoice.id} actualizada".green
  end

  def sanitized_document_gloss(document_notes)
    company_data = document_notes[/Ref:\s([0-9]){4}-([0-9]){0,2}-C([0-9]){0,6}\w+/]
    raise 'Formato inválido para obtener fecha y compañía' unless company_data.present?

    unformatted_emit_date = company_data[/([0-9]){4}-([0-9]){0,2}/]
    new_emit_date = (unformatted_emit_date + '-01').try(:to_date)
    company_id = document_notes[/C([0-9]){0,6}\w+/].try(:delete, 'C')
    { emit_date: new_emit_date, company_id: company_id }
  rescue StandardError => e
    puts "Error al escanear glosa del documento: #{e.message}".red
    {}
  end
end
