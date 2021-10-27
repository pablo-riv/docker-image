namespace :kpi do
  desc 'Set historical KPI for Delivery accomplishment (SLA) for each Company'
  task set_historical_sla: :environment do
    date_to = Date.current
    Company.find_each(batch_size: 5).each do |company|
      first_date = company.packages.where(status: :delivered).try(:first).try(:created_at).try(:to_date)
      next unless first_date.present?

      puts "===\n===Calculating SLAs for company #{company.try(:name)}, id: #{company.try(:id)}===\n===\n"
      (first_date..date_to).each do |date|
        puts "\n==== Calculating SLA for date: #{date.strftime('%Y/%m/%d')} ===="
        Kpis::SlaService.new({company: company}).recalculate_sla(date)
      end
    end
  end

  desc 'Set daily KPI for Delivery accomplishment (SLA) for each Company'
  task set_daily_sla: :environment do
    date_to = Date.current
    Company.find_each(batch_size: 5).each do |company|
      last_calculated_date = Kpi.where(kpiable_type: 'Company', kpiable_id: company.id, kind: :sla).try(:last).try(:associated_date).try(:to_date)
      next puts "There's already a SLA for date #{date_to.strftime('%Y/%m/%d')} with company #{company.name}." unless last_calculated_date != date_to

      puts "There wasn't any KPI created for company #{company.name}, id: #{company.id}. Now checking for historical packages..." unless last_calculated_date
      first_date = company.packages.where(status: :delivered).try(:first).try(:created_at).try(:to_date)
      puts "There wasn't any delivered package for company #{company.name}, id: #{company.id} yet. A new KPI will be instanciated from #{date_to.strftime('%Y/%m/%d')}" unless first_date
      start_date = last_calculated_date || first_date || date_to

      puts "===\n===Calculating SLAs for company #{company.try(:name)}, id: #{company.try(:id)}===\n===\n"
      (start_date..date_to).each do |date|
        puts "\n==== Calculating daily SLA for date: #{date.strftime('%Y/%m/%d')} ===="
        Kpis::SlaService.new({company: company}).recalculate_sla(date)
      end
    end
  end
end
