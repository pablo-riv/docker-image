module Analytics
  class Pickup < Analytic
    TODAY = Date.current

    def initialize(properties)
      super(properties)
    end

    def metrics
      valid_pickups = pickup_collection(total)
      current_pickup = valid_pickups[0]
      first_next = valid_pickups[1]
      second_next = valid_pickups[2]
      third_next = valid_pickups[3]

      RecursiveOpenStruct.new(
        pickups: {
          current: {
            provider: current_pickup.present? ? current_pickup['provider'] : nil,
            shipments: current_pickup.present? ? current_pickup.packages.size : nil,
            arrival_date: current_pickup.present? ? current_pickup['schedule']['date'] : nil,
            arrival_hour: current_pickup.present? ? current_pickup['schedule']['range_time'] : nil,
            location: current_pickup.present? ? current_pickup['address']['place'] : nil
          },
          up_next: {
            first: {
              provider: first_next.present? ? first_next['provider'] : nil,
              arrival_date: first_next.present? ? first_next['schedule']['date'] : nil,
              arrival_hour: first_next.present? ? first_next['schedule']['range_time'] : nil
            },
            second: {
              provider: second_next.present? ? second_next['provider'] : nil,
              arrival_date: second_next.present? ? second_next['schedule']['date'] : nil,
              arrival_hour: second_next.present? ? second_next['schedule']['range_time'] : nil
            },
            third: {
              provider: third_next.present? ? third_next['provider'] : nil,
              arrival_date: third_next.present? ? third_next['schedule']['date'] : nil,
              arrival_hour: third_next.present? ? third_next['schedule']['range_time'] : nil
            }
          }
        }
      )
    end

    def pickup_collection(data = [])
      return [] if data.empty?

      data.select { |pickup| pickup.schedule['date'].to_date >= TODAY }
    end
  end
end
