class DeliveryService
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  def approx_size(size)
    case size
    when 'Pequeño (10x10x10cm)' then 2
    when 'Mediano (30x30x30cm)' then 3
    when 'Grande (50x50x50cm)' then 4
    when 'Muy Grande (>60x60x60cm)' then 5
    end
  end
end
