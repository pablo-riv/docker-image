namespace :courier_engagement_rules do
  BASE_RULES = {
    'bluexpress': {
      max_date_for_delivery: 10,
      without_movement: 10,
      unanswered: 1,
      without_management: 3
    },
    'starken': {
      max_date_for_delivery: 10,
      without_movement: 10,
      unanswered: 2,
      without_management: 7
    },
    'chilexpress': {
      max_date_for_delivery: 20,
      without_movement: 20,
      unanswered: 2,
      without_management: 9
    },
    'chileparcels': {
      max_date_for_delivery: 10,
      without_movement: 10,
      unanswered: 3,
      without_management: 5
    },
    'motopartner': {
      max_date_for_delivery: 3,
      without_movement: 3,
      unanswered: 1,
      without_management: 3
    },
    'muvsmart': {
      max_date_for_delivery: 3,
      without_movement: 3,
      unanswered: 1,
      without_management: 3
    }
  }.freeze

  desc 'Create courier_engagement rules'
  task create: :environment do
    BASE_RULES.each do |key, value|
      courier = Courier.find_by(name: key.to_s)
      next if courier.blank?

      CourierEngagementRule.create(value.merge(courier_id: courier.id))
    end
  end
end
