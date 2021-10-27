class Courier < ApplicationRecord
  COURIERS_TEMPLATE = HashWithIndifferentAccess.new(
    bluexpress: { type: 'priority', available: true },
    chazki: { type: 'same_day', available: false },
    chileparcels: { type: 'priority', available: true },
    chilexpress: { type: 'priority', available: true },
    correoschile: { type: 'priority', available: false },
    dhl: { type: 'priority', available: true },
    fedex: { type: '', available: true },
    moova: { type: 'same_day', available: false },
    motopartner: { type: 'priority', available: true },
    muvsmart: { type: 'priority', available: false },
    muvsmart_mx: { type: 'same_day', available: false },
    shippify: { type: 'same_day', available: false },
    spread: { type: 'priority', available: false },
    starken: { type: 'priority', available: true }
  )

  PRIORITY_COURIERS = COURIERS_TEMPLATE.select { |_, courier| courier[:type] == 'priority'}

  SAME_DAY_COURIERS = COURIERS_TEMPLATE.select { |_, courier| courier[:type] == 'same_day'}

  AVAILABLE_COURIERS = COURIERS_TEMPLATE.select { |_, courier| courier[:available] }

  #RELATIONS
  has_many :kpis, as: :kpiable
  has_many :courier_destinies
  has_many :courier_origins
  has_many :courier_delivery_types
  has_many :courier_payment_types
  has_many :courier_service_types
  has_many :courier_transport_types
  has_many :translate_communes_couriers
  belongs_to :generic_courier
  belongs_to :country
  has_one :courier_engagement_rule
  has_many :courier_operational_informations, dependent: :destroy
  has_many :courier_aliases

  # SCOPES
  default_scope { where(deleted_at: nil) }

  # CLASS METHODS
  class << self
    def achronim_to_name(achronim)
      {
        'cxp' => 'chilexpress',
        'stk' => 'starken',
        'cc' => 'correoschile'
      }[achronim.downcase] || achronim.downcase
    rescue NoMethodError
      nil
    end

    def name_to_achronim(achronim)
      {
        'chilexpress' => 'cxp',
        'starken' => 'stk',
        'correoschile' => 'cc'
      }[achronim.downcase] || achronim.downcase
    rescue NoMethodError
      nil
    end

    def services_by_courier(courier, company_id)
      services =
        case courier
        when *PRIORITY_COURIERS.keys then %i[priority]
        when *SAME_DAY_COURIERS.keys then %i[same_day]
        else []
        end

      services_object = HashWithIndifferentAccess.new
      services.each { |service| services_object[service] = services_builder(service, courier, company_id) }
      services_object
    end

    def services_builder(service, courier, company_id)
      {
        available: company_id == 1 ? true : (service != :same_day),
        coverage: coverage_by(courier)
      }
    end

    def coverage_by(courier)
      send(:"#{courier}_coverages")
    rescue NoMethodError
      []
    end

    def moova_coverages
      ['LAS CONDES']
    end

    def muvsmart_mx_coverages
      ['SAN ANGEL - ALVARO OBREGON']
    end

    def shippify_coverages
      ['VITACURA',
       'LAS CONDES',
       'PROVIDENCIA',
       'LO BARNECHEA',
       'LA REINA',
       'NUNOA',
       'PENALOLEN',
       'SANTIAGO CENTRO',
       'QUINTA NORMAL',
       'ESTACION CENTRAL',
       'RECOLETA',
       'MACUL',
       'SAN MIGUEL',
       'RECOLETA',
       'INDEPENDENCIA',
       'HUECHURABA',
       'CONCHALI',
       'SAN JOAQUIN',
       'RENCA',
       'LA FLORIDA',
       'ESTACION CENTRAL',
       'LO PRADO',
       'QUILICURA',
       'CERRO NAVIA',
       'PUDAHUEL',
       'CERRILLOS',
       'PEDRO AGUIRRE CERDA',
       'LA GRANJA',
       'LA CISTERNA',
       'LO ESPEJO',
       'EL BOSQUE',
       'SAN RAMON',
       'LA PINTANA',
       'SAN BERNARDO',
       'MAIPU',
       'PUENTE ALTO']
    end

    def chazki_coverages
      ['LAS CONDES']
    end

    def available_with_same_day_delivery
      select { |courier| courier.services['same_day'] }
    end

    def ssd_couriers_names
      where("services ->> 'same_day' = 'true'").pluck(:symbol)
    end
  end
end
