namespace :management_step do
  STEPS = [
    { name: 'status_asked', step: 1 }, { name: 'service_on_hold', step: 2 },
    { name: 'service_taken', step: 3 },
    { name: 'incomplete_service', step: 4 }, { name: 'solved_service', step: 5 }
  ].freeze

  SUBSTATUS = {
    'status_asked': ['received_for_courier', 'in_route', 'in_transit'],
    'service_on_hold': ['first_closed_address', 'second_closed_address', 'objected', 'incomplete_address', 'unexisting_address',
                        'reused_by_destinatary', 'unknown_destinatary', 'unreachable_destiny', 'failed', 'packaging_solicited'],
    'service_taken': ['in_route', 'in_transit'],
    'solved_service': ['delivered','indemnify','indemnify_out_of_date','at_shipit','strayed','damaged','returned'],
    'incomplete_service': []
  }

  desc 'Create management steps'
  task create_management_steps: :environment do
    STEPS.each { |step| ManagementStep.create(step) }
  end

  desc 'Create statuses management step'
  task create_status_management_steps: :environment do
    SUBSTATUS.each do |key, value|
      management_step = ManagementStep.find_by(name: key)
      value.each do |item|
        sub_status = SubStatus.find_or_create_by(name: item)
        management_step.sub_statuses << sub_status
      end
    end
  end
end
