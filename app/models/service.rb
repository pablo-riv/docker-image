class Service < ApplicationRecord
  ## RELATIONS
  has_many :settings
  validates :name, uniqueness: true

  def fulfillment?
    id == 4
  end

  def pp?
    id == 3
  end

  def self.allowed_attributes
    [:name, :price]
  end

  def real_name
    case name
    when 'opit' then 'Opit'
    when 'fullit' then 'Integraciones'
    when 'pp' then 'Pick & Pack'
    when 'fulfillment' then 'Fulfillment'
    when 'sd' then 'Shipit Delivery'
    when 'notification' then 'Notificaciones'
    when 'printers' then 'Impresiones'
    when 'analytics' then 'Analiticas'
    when 'll' then 'Labelling'
    when 'automatizations' then 'Automatizations'
    end
  end
end
