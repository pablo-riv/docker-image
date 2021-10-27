class PrinterJob < ApplicationJob
  queue_as :printers

  def perform(packages, printer)
    packages.each do |package|
      PrinterService.new(package: package,
                         printer: printer,
                         job_name: 'printing-ticket-for-label-clients').deliver
      package.update_columns(label_printed: true, printed_date: Date.current)
    end
  rescue => e
    Slack::Ti.new({}, {}).alert('', "🖨 Cliente #{packages.first.branch_office.company.name} no puede imprimir\n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end
end
