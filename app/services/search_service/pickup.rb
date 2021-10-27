module SearchService
  class Pickup
    COURIERS = ['chilexpress', 'starken', 'muvsmart', 'motopartner', 'chileparcels', 'bluexpress', 'shipit', '', nil].freeze
    STATES = [0, 1, 2, 3, 4, 5].freeze
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      pickups = 
        if id.present?
          ::Pickup.includes(:packages, :manifest).where(id: id).where(packages: { branch_office_id: branch_offices })
        else
          ::Pickup.includes(:packages, :manifest).where(packages: { branch_office_id: branch_offices })
                  .where(status: state, created_at: from_date..to_date).order(id: :desc)
        end
      paginated = Kaminari.paginate_array(pickups).page(page).per(per)
      { pickups: paginated, total: paginated.total_count }
    end

    private

    def id
      properties[:id]
    end

    def courier
      properties[:courier].present? && properties[:courier].try(:downcase) != 'all' ? properties[:courier].downcase : COURIERS
    end

    def state
      return STATES unless properties[:state].present?
      return STATES if properties[:state].try(:downcase) == 'all'

      properties[:state].split(',').map { |state| translate_status(state) }
    end

    def from_date
      properties[:from_date].try(:to_date).try(:at_beginning_of_day)
    end

    def to_date
      properties[:to_date].try(:to_date).try(:at_end_of_day)
    end

    def branch_offices
      properties[:branch_offices]
    end

    def per
      properties[:per]
    end

    def page
      properties[:page]
    end

    def translate_status(status)
      case status
      when 'pending' then 0
      when 'shipped' then 1
      when 'shipped_with_issues' then 2
      when 'failed' then 3
      when 'cancelled' then 4
      when 'no_retired' then 5
      end
    end
  end
end
