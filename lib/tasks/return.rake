namespace :return do
  desc 'Processing pick and pack returns'
  task pick_and_pack_process: :environment do
    puts '[BEGIN] Processing pick and pack returns'.green
    begin
      ApiIntegration::InternalServices::Returns.new.pick_and_pack_process
    rescue StandardError => exception
      puts "Error to process pick and pack returns\n Error: #{exception.message}--".red
    end
    puts '[END] Processing pick and pack returns'.green
  end
end
