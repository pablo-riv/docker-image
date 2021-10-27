module Price
  class Packing
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def calculate
      price =
        case packing
        when 'bolsa courier + burbuja' then packaging_courier_bag_burbuja
        when 'caja de cartón' then packing_carton
        when 'film plástico' then packing_plastico
        when 'caja + burbuja' then packing_burbuja
        when 'papel kraft' then packing_kraft
        when 'bolsa courier' then packing_plastico
        when 'sin empaque' then 0
        end
    end

    private

    def volume_price
      (height * width * length / 4000)
    end

    def height
      properties[:height]
    end

    def width
      properties[:width]
    end

    def length
      properties[:length]
    end

    def packing
      properties[:packing].try(:downcase) || 'sin empaque'
    end

    def packaging_courier_bag_burbuja
      case volume_price
      when 0..3 then 850
      when 3.01..6 then 950
      when 6.01..15 then 1100
      else 1400
      end
    end

    def packing_carton
      case volume_price
      when 0..3 then 650 #450
      when 3.01..6 then 800 #600
      when 6.01..15 then 1000 #800
      else 1200 #1000
      end
    end

    def packing_plastico
      case volume_price
      when 0..3 then 500 #300
      when 3.01..6 then 550 #350
      when 6.01..15 then 600 #400
      else 650 #450
      end
    end

    def packing_burbuja
      case volume_price
      when 0..3 then 950 #750
      when 3.01..6 then 1050 #850
      when 6.01..15 then 1200 #1000
      else 1500 #1300
      end
    end

    def packing_kraft
      case volume_price
      when 0..3 then 500 #300
      when 3.01..6 then 550 #350
      when 6.01..15 then 600 #400
      else 650 #450
      end
    end

    def packing_courier_bag
      case volume_price
      when 0..3 then 500 #300
      when 3.01..6 then 550 #350
      when 6.01..15 then 600 #400
      else 650 #450
      end
    end
  end
end
