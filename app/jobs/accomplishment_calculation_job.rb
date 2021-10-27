class AccomplishmentCalculationJob < ApplicationJob
  queue_as :default

  def perform(company)
    packages = company.packages.left_outer_joins(:check)
                      .select("checks.in ->> 'created_at' AS in_created_at, checks.in ->> 'branch_office_id' AS in_branch_office_id,
                              checks.out ->> 'created_at' AS out_created_at, checks.out ->> 'tracking_number' AS out_tracking_number,
                              packages.id, packages.created_at, packages.mongo_order_id, packages.status,
                              packages.courier_status_updated_at, packages.delayed, packages.delivery_time")
    return if packages.size.zero?

    Accomplishment.process(packages, company)
  end
end
