module SearchService
  class Order
    COURIERS = ['chilexpress', 'dhl', 'starken', 'correoschile', 'correos_de_chile', 'muvsmart', 'motopartner', 'chileparcels', 'bluexpress', 'shippify', ''].freeze
    DESTINIES = ['courier_branch_office', 'home_delivery', ''].freeze
    SELLERS = ['shopify', 'bootic', 'bsale', 'vtex', 'woocommerce', 'prestashop', 'jumpseller', 'mercadolibre', ''].freeze
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      orders =
        if search_query.present?
          ApplicationRecord::Order.searching_by_company(company.id, search_query, page, per)
                                  .search_with_commune_name
        else
          courier_query = courier
          destiny_query = destiny_kind
          seller_query = seller
          destiny_commune_query = destiny_commune_id
          result = ::Order.search_with_commune_name
                          .between_dates(from: from_date, to: to_date)
                          .where(company_id: company.id)
          result = result.where(payable: payables) if payables.size.positive?
          result = result.where(state: state) if state.size.positive?
          result = result.where(courier_query[:query], courier_query[:search]) if courier_query[:search].size.positive?
          result = result.where(seller_query[:query], seller_query[:search]) if seller_query[:search].size.positive?
          result = result.where(destiny_query[:query], destiny_query[:search]) if destiny_query[:search].size.positive?
          result = result.where(destiny_commune_query[:query], destiny_commune_query[:search]) if destiny_commune_query[:search].size.positive?
          result.order(reference: :desc).load
        end
      { orders: Kaminari.paginate_array(orders).page(page).per(per), total: orders.size }
    rescue => e
      Slack::Ti.new({}).alert('', "System Error: #{e.message}\n Bug Trace: #{e.backtrace[0]}")
      { orders: [], total: 0 }
    end

    private

    def courier
      if properties[:courier].present? && properties[:courier].try(:downcase) != 'all'
        query = "LOWER(orders.courier ->> 'client') IN (?)"
        search = [properties[:courier].downcase]
      else
        search = []
      end
      { query: query, search: search }
    end

    def seller
      if properties[:seller].present? && properties[:seller].try(:downcase) != 'all'
        query = "LOWER(orders.seller ->> 'name') IN (?)"
        search = [properties[:seller].downcase]
      else
        search = []
      end
      { query: query, search: search }
    end

    def destiny_commune_id
      if properties[:communes].present? && properties[:communes].try(:downcase) != 'all'
        query = "LOWER(orders.destiny ->> 'commune_id') IN (?)"
        search = properties[:communes].split(',')
      else
        search = []
      end
      { query: query, search: search }
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

    def destiny_kind
      if properties[:destiny_kind].present?
        query = "LOWER(orders.destiny ->> 'kind') IN (?)"
        search = [properties[:destiny_kind].downcase]
      else
        search = []
      end
      { query: query, search: search }
    end

    def from_date
      properties[:from_date].try(:to_date).try(:beginning_of_day)
    end

    def to_date
      properties[:to_date].try(:to_date).try(:at_end_of_day)
    end

    def company
      properties[:company]
    end

    def per
      properties[:per]
    end

    def page
      properties[:page]
    end

    def search_query
      properties[:search]
    end

    def translate_status(state)
      case state
      when 'draft' then 0
      when 'confirmed' then 1
      when 'deliver' then 2
      when 'canceled' then 3
      when 'archived' then 4
      end
    end
  end
end
