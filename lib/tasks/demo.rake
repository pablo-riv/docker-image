namespace :demo do
  desc 'Create shipments data for demo'
  task shipments: :environment do
    company = Company.find(3642)
    branch_office = company.default_branch_office
    logs = []
    CSV.foreach("#{Rails.root}/lib/data/demo/shipments.csv", headers: true) do |row|
      data = row.to_hash.with_indifferent_access
      package = Package.find_by(id: data[:id])
      (logs << "SHIPMENT: #{package.id}".red.swap && next) unless package.present?

      shipment = package.dup.attributes.with_indifferent_access
      shipment[:id] = nil
      shipment[:branch_office_id] = branch_office.id
      shipment[:reference] = data[:reference]
      shipment[:status] = data[:status]
      shipment[:courier_for_client] = data[:starken]
      shipment[:tracking_number] = data[:tracking]
      shipment[:created_at] = data[:created_at]
      shipment[:operation_date] = data[:operation_date]
      shipment[:courier_status_updated_at] = package.courier_status_updated_at.to_date
      shipment[:fulfillment_files] = package.fulfillment_files.try(:to_h)
      shipment[:purchase] = {
        amount: package.purchase['amount'],
        max_insurance: package.purchase['max_insurance'],
        ticket_number: package.purchase['ticket_number'],
        extra_insurance: package.purchase['extra_insurance'].class.to_s == 'String' ? I18n.t(package.purchase['extra_insurance']) : package.purchase['extra_insurance'],
        insurance_price: package.purchase['insurance_price']
      }.with_indifferent_access

      shipment[:insurance_attributes] = package.insurance.dup.attributes.except('package_id') if package.insurance.present?
      shipment[:address_attributes] = package.address.dup.attributes.except('package_id')

      cloned = branch_office.packages.create!(shipment)
      (logs << "SHIPMENT: #{package.id}".red.swap && next) unless cloned.persisted?
      cloned.create_accomplishment(package.accomplishment.dup.attributes.except('package_id')) if package.accomplishment.present?
      cloned.create_check(package.check.dup.attributes.except('package_id')) if package.check.present?
      package.alerts do |alert|
        cloned.alerts.create(alert.dup.except('package_id'))
      end

      package.whatsapps do |whatsapp|
        cloned.whatsappscreate(whatsapp.dup.except('package_id'))
      end

      logs << "SHIPMENT: #{cloned.id}".green.swap
    end

    logs.each { |l| puts l }
  end

  desc 'Create invoices data for demo'
  task invoices: :environment do
    company = Company.find(3642)
    company.invoices.create(state: :no_emited,
                            emit_date: Date.current.at_beginning_of_month,
                            due_date: Date.current.at_beginning_of_month + 1.month,
                            net: company.packages.by_date(Date.current.month).pluck(:total_price).map(&:to_f).sum)
    company.invoices.create(state: :expired_soon,
                            emit_date: Date.current.at_beginning_of_month - 1.month,
                            due_date: Date.current.at_beginning_of_month,
                            net: company.packages.by_date(Date.current.month - 1.month).pluck(:total_price).map(&:to_f).sum)
    company.invoices.create(state: :paid,
                            emit_date: Date.current.at_beginning_of_month - 2.months,
                            due_date: Date.current.at_beginning_of_month - 1.month,
                            net: company.packages.by_date(Date.current.month - 2.months).pluck(:total_price).map(&:to_f).sum)
  end

  desc 'Create tickets data for demo'
  task tickets: :environment do
    company = Company.find(3642)
    account = company.current_account
    logs = []
    packages = company.packages.pluck(:id, :reference, :tracking_number)
    subjects = ['Consulta sobre un envío', 'RE: Pieza xxxxx devuelta a Shipit', 'AYUDA CUSTOMIZACIÓN CORREOS', 'Otro Motivo: No aplica', 'Notificaron una perdida de envío, adjunte la bolet...']
    CSV.foreach("#{Rails.root}/lib/data/demo/tickets.csv", headers: true) do |row|
      data = row.to_hash.with_indifferent_access
      package = packages.sample
      ticket = {
        package_id: package[0],
        subject: subjects.sample,
        kind: data[:kind],
        priority: '',
        messages: [{ message: data[:message], created_at: Date.current, user: 'end_user' }],
        package_reference: package[1],
        other_subject: '',
        package_tracking: package[2],
        requester_type: data[:requester_type],
        requester_email: data[:requester_email],
        status: data[:status],
        ticket_id: data[:ticket_id]
      }.with_indifferent_access
      support = account.supports.create(ticket)
      (logs << "SUPPORT: #{data[:ticket_id]}".red.swap && next) unless support.persisted?

      logs << "SUPPORT: #{support.id}".green.swap
    end
    logs.each { |l| puts l }
  end

  desc 'Update all demo shipments'
  task update: :environment do
    logs = []
    company = Company.find(3642)
    company.packages.each do |package|
      updated = package.update_columns(created_at: (package.created_at + 1.day), operation_date: (package.operation_date + 1.day))
      (logs << "SHIPMENT: #{package.id}".red.swap && next) unless updated

      logs << "SHIPMENT: #{package.id}".green.swap
    end
    company.orders.update_all(created_at: Date.current + 1.day)

    if Date.current.day == Date.current.end_of_month.day
      invoices = company.invoices
      invoice_no_emited = invoices.find { |i| i.state == 'no_emited' }
      invoice_expired_soon = invoices.find { |i| i.state == 'expired_soon' }
      invoice_paid = invoices.find { |i| i.state == 'paid' }

      invoice_no_emited.update_columns(emit_date: Date.current.next_month.at_beginning_of_month, due_date: Date.current.next_month.at_beginning_of_month + 1.month)
      invoice_expired_soon.update_columns(emit_date: Date.current.next_month.at_beginning_of_month - 1.month, due_date: Date.current.next_month.at_beginning_of_month)
      invoice_paid.update_columns(emit_date: Date.current.next_month.at_beginning_of_month - 2.months, due_date: Date.current.next_month.at_beginning_of_month - 1.month)
    end
  end
end
