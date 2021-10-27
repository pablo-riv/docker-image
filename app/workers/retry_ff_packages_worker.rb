class RetryFfPackagesWorker
  include Sidekiq::Worker
  sidekiq_options retry: 6

  def perform(args)
    packages = args['packages'].include?('packages') ? args['packages']['packages'] : args['packages']
    packages = packages.select{ |package| FulfillmentService.order_skus(package['id']).include?('error') }
    return if packages.blank?
    puts "retrying send ff packages for bo: #{packages.first['branch_office_id']}".yellow
    success = FulfillmentService.create_package({ packages: packages }, args['company_id'])
    puts "response: #{success.to_s}".yellow
    self.class.perform_in(15.minutes, {packages: packages, company_id: args['company_id']}) unless success == true || !success['message'].to_s.downcase.include?('no hay stock disponible')
  rescue => e
    puts "Cant retry ff package sent cz of: #{e.message}".yellow
    self.class.perform_in(15.minutes, {packages: args['packages'], company_id: args['company_id']})
  end
end
