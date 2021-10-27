namespace :couriers_branch_office do
  desc 'Set deleted al value to branches archived'
  task set_deleted_at_to_branches_archived: :environment do
    puts '### Start to update couriers branch offices ###'
    begin
      CouriersBranchOffice.where(archive: true).update_all(deleted_at: Time.now)
    rescue StandardError => e
      puts "Error al actualizar couriers branch office \n Error: #{e.message}--".yellow
    end
    puts '### End to update couriers branch offices ###'
  end
end
