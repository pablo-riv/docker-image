module PickAndPacks
  class ByCuttingHour
    attr_accessor :hour
    def initialize(current_date)
      @hour = current_date.strftime('%H')
    end

    def pick_and_packs
      PickAndPack
        .joins('
          LEFT JOIN cutting_hours ON pick_and_packs.id = cutting_hours.cutting_id')
        .where(
          cutting_hours: {
            cutting_type: 'PickAndPack', pick_and_pack_service: @hour
          }
        )
    end

  end
end
