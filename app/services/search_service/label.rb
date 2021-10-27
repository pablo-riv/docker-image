module SearchService
  class Label
    COURIERS = ['chilexpress', 'dhl', 'starken', 'correoschile', 'correos_de_chile', 'muvsmart', 'glovo', 'motopartner', 'chileparcels', 'bluexpress', 'shippify', 'empty_courier', ''].freeze
    STATES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19].freeze
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      labels = ::Package.left_outer_joins(:address, address: :commune, commune: :region)
                        .where(is_payable: payables, status: [0, 13, 14, 6], branch_office_id: branch_offices, label_printed: printed?)
                        .where("LOWER(coalesce(packages.courier_for_client,'empty_courier')) IN (?)", courier)
                        .where('CASE WHEN ? THEN reference IS NOT NULL ELSE packages.tracking_number IS NOT NULL AND packages.pack_pdf IS NOT NULL AND packages.url_pack IS NOT NULL END', format?)
                        .where('CASE WHEN ? THEN packages.reference = ? ELSE packages.reference IS NOT NULL END', reference.present?, reference)
                        .where('CASE WHEN ? THEN addresses.commune_id IS NOT NULL ELSE addresses.commune_id = ? END', ['all', '', nil].include?(commune), commune.to_i)
                        .where('LOWER(packages.destiny) SIMILAR TO ?', destiny)
                        .where('CASE WHEN ? THEN packages.mongo_order_seller = ? ELSE packages.mongo_order_seller IS NULL OR(packages.mongo_order_seller IS NOT NULL) END', seller.present?, seller)
                        .where('CASE WHEN ? THEN packages.created_at::date BETWEEN ? AND ? ELSE packages.created_at IS NOT NULL END', to_date.present? && from_date.present?, from_date, to_date)
                        .where('CASE WHEN ? THEN packages.id IN (?) ELSE packages.id IS NOT NULL END', packages.present?, packages)
                        .not_sandbox.not_test.no_returned.without_checks
                        .label_select.order(order_mode).load
      { labels: labels, total: labels.size }
    end

    private

    def order_mode
      return "ARRAY_POSITION(ARRAY[#{packages.join(',')}], packages.id)" if packages.present?

      'packages.id desc, packages.reference asc'
    end

    def courier
      ['all', '', nil].include?(properties[:courier]) ? COURIERS : properties[:courier].downcase
    end

    def payables
      return [false, true] if properties[:payable] == 'all'
      return [false, true] unless properties[:payable].present?

      ActiveRecord::Type::Boolean.new.cast(properties[:payable])
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

    def reference
      properties[:reference]
    end

    def seller
      properties[:seller]
    end

    def commune
      properties[:commune]
    end

    def packages
      properties[:packages]
    end

    def destiny
      destinies = %w[sucursal chilexpress starken correoschile domicilio]
      return similar_to(destinies) if properties[:destiny] == 'all'
      return similar_to(destinies) unless properties[:destiny].present?

      result =
        if %w[courier_branch_office sucursal].include?(properties[:destiny])
          destinies.delete('domicilio')
          destinies
        else
          ['domicilio']
        end
      similar_to(result)
    end

    def format?
      properties[:format].downcase == 'pdf'
    rescue => e
      false
    end

    def similar_to(result)
      "%(#{result.join('|')})%"
    end

    def printed?
      return [false, true] unless properties[:label_printed].present?

      ActiveRecord::Type::Boolean.new.cast(properties[:label_printed])
    end
  end
end
