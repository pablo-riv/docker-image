class PrinterService
  attr_accessor :properties, :print_service, :errors

  def initialize(properties)
    @properties = properties
    @errors = []
    @print_client = lambda do |job|
      authentication = PrintNode::Auth.new(Rails.configuration.printnode_token)
      client = PrintNode::Client.new(authentication)
      client.create_printjob(job)
    end
  end

  def deliver
    job = PrintNode::PrintJob.new(printer, package.id.to_s, 'pdf_uri', package.pack_pdf.to_s, job_name)
    @print_client.call(job)
    update_package
  end

  private

  def job_name
    @properties[:job_name] || 'printing-ticket-for-app'
  end

  def package
    @properties[:package]
  end

  def printer
    @properties[:printer]
  end

  def account
    @properties[:account]
  end

  def update_package
    package.update_columns(is_courier_printed: true)
  end
end
