module SearchService
  class Sku
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      find_skus = data
      { total: find_skus[:total], skus: find_skus[:skus].map { |sku| RecursiveOpenStruct.new(sku, recurse_over_arrays: true) } }
    end

    private

    def data
      FulfillmentService.skus_by_client(@properties)
    end
  end
end
