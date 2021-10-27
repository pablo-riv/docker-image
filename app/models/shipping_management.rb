class ShippingManagement < ApplicationRecord
  # RELATIONS
  belongs_to :package
  has_many :management_processes

  enum kind: { overdue: 0, returned: 1, lost: 2, other: 3 }
  enum status: { pending: 0, cancelled: 1, solved: 2 }

  def with_service_on_hold?
    management_processes.includes(:management_step)
                        .map(&:step_name)
                        .count('service_on_hold') > 1
  end
end
