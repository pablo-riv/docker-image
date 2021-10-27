module Charges
  class Generator
    include Uploader
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def run
      dispatcher = instance
      dispatcher.calculate
    end

    def make_download
      dispatcher = instance
      upload(charges: dispatcher.calculate,
             name: report_name,
             service: properties[:service])
    end

    def details
      dispatcher = Charges::Dispatcher.new(period: period,
                                           service: properties[:service],
                                           data: details_data,
                                           specific: properties[:specific],
                                           kind: properties[:kind]).instance
      dispatcher.details
    end

    private

    def instance
      Charges::Dispatcher.new(period: period,
                              service: properties[:service],
                              data: data,
                              kind: properties[:kind]).instance
    end

    def period
      Charges::Period.new(date: properties[:date], kind: properties[:kind]).exec
    end

    def data
      Charges::Collect.new(service: properties[:service], periods: period, company: properties[:company]).exec
    end

    def details_data
      Charges::Collect.new(specific: properties[:specific],
                           service: properties[:service],
                           periods: period,
                           company: properties[:company],
                           per: properties[:per],
                           page: properties[:page]).details
    end

    def report_name
      "#{properties[:company].name.tr('/', '_').upcase}_CARGOS"\
      "_#{properties[:service].upcase}_"\
      "#{I18n.t(properties[:kind]).upcase}_"\
      "#{I18n.l(period.first, format: (properties[:kind] == 'monthly' ? '%B-%Y' : '%Y')).upcase}"
    end
  end
end
