module SearchService
  class Shipment
    COURIERS = ['chilexpress', 'dhl', 'starken', 'correoschile', 'correos_de_chile', 'muvsmart', 'glovo', 'motopartner', 'chileparcels', 'bluexpress', 'shippify', 'empty_courier', 'fulfillment delivery', '', nil].freeze
    STATES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].freeze
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      if query.present?
        results = ApplicationRecord::Package.searching(current_account, query, page, per)
        { shipments: results, total: results.size }
      else
        data = ::Package.joins(:address, address: :commune).includes(:pickups, :supports, :insurance, :alerts, :whatsapps, :check)
        data = data.where(id: ids) unless ids.size.zero?
        data = data.where(created_at: from_date..to_date, branch_office_id: branch_offices) if ids.size.zero?
        data = data.where(is_returned: returned) unless returned.size.zero?
        data = data.where(is_payable: payables) unless payables.size.zero?
        data = data.where(status: state) unless state.size.zero?
        data = data.where(label_printed: printed) unless printed.size.zero?
        data = data.where("LOWER(coalesce(packages.courier_for_client,'empty_courier')) IN (?)", courier) unless courier.size.zero?
        data = data.where('LOWER(packages.destiny) SIMILAR TO ?', destiny.first) unless destiny.size.zero?
        data = data.where(addresses: { commune_id: communes }) unless communes.size.zero?
        data = data.not_sandbox.not_test.order(sorter => sorter_by).page(page).per(per).load
        { shipments: data, total: data.total_count }
      end
    end

    def download
      if query.present?
        results = ApplicationRecord::Package.searching(current_account, query)
        { shipments: results, total: results.size }
      else
        data = ::Package.joins(:address, address: :commune).includes(:supports, :insurance, :alerts, :whatsapps, :check).where(created_at: from_date..to_date, branch_office_id: branch_offices)
        data = data.where(is_returned: returned) unless returned.size.zero?
        data = data.where(is_payable: payables) unless payables.size.zero?
        data = data.where(status: state) unless state.size.zero?
        data = data.where(label_printed: printed) unless printed.size.zero?
        data = data.where("LOWER(coalesce(packages.courier_for_client,'empty_courier')) IN (?)", courier) unless courier.size.zero?
        data = data.where('LOWER(packages.destiny) SIMILAR TO ?', destiny.first) unless destiny.size.zero?
        data = data.where(addresses: { commune_id: communes }) unless communes.size.zero?
        data = data.not_sandbox.not_test.order(id: :desc).load
        { shipments: data, total: data.size }
      end
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

    def state
      return [] unless properties[:state].present?
      return [] if properties[:state].try(:downcase) == 'all'

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

    def current_account
      properties[:current_account]
    end

    def per
      properties[:per]
    end

    def page
      properties[:page]
    end

    def printed
      return [] unless properties[:label_printed].present?

      [ActiveRecord::Type::Boolean.new.cast(properties[:label_printed])]
    end

    def destiny
      destinies = ['sucursal', 'chilexpress', 'starken', 'correoschile', 'domicilio', 'retiro cliente', 'despacho retail']
      return [] if properties[:destiny] == 'all'
      return [] unless properties[:destiny].present?

      result =
        if %w[courier_branch_office sucursal].include?(properties[:destiny])
          destinies.delete('domicilio')
          destinies
        else
          ['domicilio']
        end
      [similar_to(result)]
    end

    def similar_to(result)
      "%(#{result.join('|')})%"
    end

    def query
      properties[:query]
    end

    def ids
      properties[:ids] || []
    end

    def translate_status(status)
      case status
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
      return 'desc' unless %w(asc desc).include?(properties[:sorter_by])

      properties[:sorter_by]
    end

    def communes
      return [] unless properties[:communes].present?
      return [] if properties[:communes].try(:downcase) == 'all'

      properties[:communes].split(',')
    end
  end
end
