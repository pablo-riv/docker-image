
module Shipments
  module Error
    class ShipmentError
      attr_accessor :shipment, :message, :how_to_solve, :bugtrace
      def initialize(shipment: {}, reference: '', message: '', how_to_solve: '', bugtrace: nil)
        @shipment = shipment
        @message = message
        @how_to_solve = how_to_solve
        @bugtrace = bugtrace
      end

      def error_message
        { shipment: @shipment,
          message: @message,
          how_to_solve: @how_to_solve,
          bugtrace: @bugtrace }
      end

      class ErrorShipmentExist < ShipmentError
        def initialize(shipment: {}, bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: 'Cambia el ID de tu envío',
                message: "Envío #{shipment.try(:reference)}: ID de Envío ya utilizado",
                bugtrace: bugtrace)
        end
      end

      class ErrorCommuneNotFound < ShipmentError
        def initialize(shipment: {}, bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: 'Revisa la comuna ingresada, esta comuna deber pertecer a las comunas habilitadas por Shipit',
                message: "Envío #{shipment[:reference]}: Comuna no encontrada",
                bugtrace: bugtrace)
        end
      end
      
      class ShipmentDoesntBuild < ShipmentError
        def initialize(shipment: {}, message: '', bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: '',
                message: "Envío: #{shipment[:reference]}: #{message}",
                bugtrace: bugtrace)
        end
      end
      
      class ShipmentDoesntPersist < ShipmentError
        def initialize(shipment: {}, bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: '',
                message: "Envío #{shipment.try(:reference)}: El envío no pudo ser creado",
                bugtrace: bugtrace)
        end
      end

      class ShipmentCreationFailed < ShipmentError
        def initialize(shipment: {}, message: '', bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: '',
                message: "Envío #{shipment.try(:reference)}: #{message}",
                bugtrace: bugtrace)
        end
      end

      class ShipmentOutOfStrock < ShipmentError
        def initialize(shipment: {}, message: '', sku: nil, bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: 'Genera una solicitud de ingreso para este SKU',
                message: "Envío #{shipment[:reference]}: No tienes stock disponible del SKU #{sku}",
                bugtrace: bugtrace)
        end
      end

      class ErrorNotCourierDestinyAvailable < ShipmentError
        def initialize(shipment: {}, bugtrace: nil)
          super(shipment: shipment,
                how_to_solve: 'Revisa la comuna y el courier ingresados.',
                message: "Envío #{shipment[:reference]}: No podremos entregar los siguientes pedidos a destino dado que nuestros couriers no llegan",
                bugtrace: bugtrace)
        end
      end
    end
  end
end
