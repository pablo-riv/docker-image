module SearchService
  class Search
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      shipments = ApplicationRecord::Package.searching(company.current_account, query, page, per)
      { data: shipments, total: shipments.size }
    end

    private

    def company
      properties[:company]
    end

    def page
      properties[:page]
    end

    def per
      properties[:per]
    end

    def query
      properties[:query]
    end
  end
end
