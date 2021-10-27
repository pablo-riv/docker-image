class Kpi < ApplicationRecord
  belongs_to :kpiable, polymorphic: true
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  validates_presence_of :kind, :associated_date, :associated_courier, :aggregation, :entity_type, :entity_accumulated_quantity, :kpiable_type, :kpiable_id, on: :create

  enum kind: { sla: 0 }
  enum aggregation: { global: 0, day: 1, week: 2, month: 3, quarter: 4, semester: 5, year: 6 }

  def self.global_sla(courier = 'shipit', date = Date.current)
    slas = where(kind: :sla, kpiable_type: 'Company', associated_date: date.beginning_of_day, aggregation: :day, associated_courier: courier).pluck(:value)
    return 0 unless slas.present?

    (slas.try(:sum) / slas.try(:size)).round(1)
  end

  def self.last_calculated_package_id(kpiable_type: nil, kpiable_id: nil, entity_type: nil, date_to: nil, kind: nil)
    id = where(kpiable_type: kpiable_type,
               kpiable_id: kpiable_id,
               kind: kind,
               entity_type: entity_type,
               associated_date: (date_to.to_date - 1.day)..(date_to),
               associated_courier: 'shipit')
         .try(:last).try(:entity_last_checked_id)
    puts "Last id with date #{date_to.strftime('%Y/%m/%d')} selected: #{id || "ID not found.\nThe first available package of the company will be selected)."}"
    Rails.logger.info "There isn't any KPI with kind: '#{kind}' & entity_type '#{entity_type}' with this date, or the day previous yet.".red unless id.present?
    id || Company.find(kpiable_id).packages.where(status: :delivered).try(:first).try(:id)
  end
end
