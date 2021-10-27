module SearchService
  class Package
    COURIERS = ['chilexpress', 'dhl', 'starken', 'correoschile', 'correos_de_chile', 'muvsmart', 'glovo', 'motopartner', 'chileparcels', 'bluexpress', 'shippify', 'empty_courier', 'fulfillment delivery', nil, ''].freeze
    STATES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].freeze
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      packages = ::Package.joins(:address, address: :commune).where(created_at: from_date..to_date, branch_office_id: branch_offices)
      packages = packages.where(is_returned: returned) unless returned.size.zero?
      packages = packages.where(is_payable: payables) unless payables.size.zero?
      packages = packages.where(status: status) unless status.size.zero?
      packages = packages.where("LOWER(coalesce(packages.courier_for_client,'empty_courier')) IN (?)", courier) unless courier.size.zero?
      packages.not_sandbox.not_test.order(id: :desc)
    end

    def filter
      packages = ::Package.joins(:address, address: :commune).where(updated_at: from_date..to_date, branch_office_id: branch_offices)
      packages = packages.where(status: state) unless state.size.zero?
      packages = packages.where("LOWER(coalesce(packages.courier_for_client,'empty_courier')) IN (?)", courier) unless courier.size.zero?
      packages = packages.not_sandbox.not_test.order(sorter => sorter_by).load
      { packages: Kaminari.paginate_array(packages).page(page).per(per), total: packages.size }
    rescue StandardError => _e
      { packages: [], total: 0, error: 'Los parámetros ingresados para filtrar están erróneos' }
    end

    private

    def courier
      properties[:courier].present? && %w[todos all].exclude?(properties[:courier].try(:downcase)) ? [properties[:courier].downcase] : []
    end

    def returned
      return [] unless properties[:returned].present?
      return [ActiveRecord::Type::Boolean.new.cast(properties[:returned])] if properties[:returned].present? && properties[:payables].present? && properties[:payables] != 'true'
      return [false] if properties[:payables].present? && properties[:payables] == 'true' || properties[:returned] == 'false'

      [ActiveRecord::Type::Boolean.new.cast(properties[:returned])]
    end

    def payables
      return [] unless properties[:payables].present?

      [ActiveRecord::Type::Boolean.new.cast(properties[:payables])]
    end

    def status
      return [] if properties[:status].present? && properties[:status].try(:downcase) == 'todos' || !properties[:status].present?

      translate_status(properties[:status])
    end

    def state
      return [] unless properties[:state].present?
      return [] if properties[:state].try(:downcase) == 'all'

      properties[:state].split(',').map { |state| translate_status(state) }
    end

    def from_date
      return Date.today.at_beginning_of_month unless properties[:from_date].present?

      properties[:from_date].try(:to_date).try(:at_beginning_of_day)
    end

    def to_date
      return Date.current unless properties[:to_date].present?

      properties[:to_date].try(:to_date).try(:at_end_of_day)
    end

    def branch_offices
      properties[:branch_offices]
    end

    def translate_status(status_name)
      case status_name
      when 'in_preparation' then 0
      when 'in_route' then 1
      when 'delivered' then 2
      when 'failed' then 3
      when 'by_retired' then 4
      when 'other' then 5
      when 'pending' then 6
      when 'to_marketplace' then 7
      when 'indemnify' then 8
      when 'ready_to_dispatch' then 9
      when 'dispatched' then 10
      when 'at_shipit' then 11
      when 'returned' then 12
      when 'created' then 13
      when 'requested' then 14
      when 'retired_by' then 15
      when 'received_for_courier' then 17
      when 'failed_with_observations' then 18
      when 'almost_failed' then 19
      when 'fulfillment' then 20
      when 'returned_in_route' then 21
      when 'crossdock' then 22
      end
    end

    def sorter
      return 'id' unless %w[id reference created_at updated_at status].include?(properties[:sorter])

      properties[:sorter]
    end

    def sorter_by
      return 'desc' unless %w[asc desc].include?(properties[:type_order])

      properties[:sorter_by]
    end

    def page
      return 1 unless properties[:page].present? || properties[:page].try { |p| p.to_i.positive? }

      properties[:page].to_i
    end

    def per
      return 50 unless properties[:per].present? || properties[:per].try { |p| p.to_i.positive? }

      properties[:per].to_i > 250 ? 250 : properties[:per]
    end
  end
end
