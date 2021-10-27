module Couriers
  module Error
    class CourierError < ::StandardError; end

    class ErrorDestiny < CourierError
      attr_reader :reference
      def initialize(reference = '', msg = 'No realizar un envío con el courier seleccionado a la sucursal seleccionada codigo envío: ')
        msg += reference || 'Sin Id Pedido'
        super(msg)
      end
    end

    class ErrorNotPayable < CourierError
      attr_reader :reference
      def initialize(reference = '', msg = 'Courier seleccionado no tiene la opción por pagar codigo envío: ')
        msg += reference || 'Sin Id Pedido'
        super(msg)
      end
    end

    class ErrorNotDestinyPayable < CourierError
      attr_reader :reference
      def initialize(reference = '', msg = 'El courier seleccionado no permite la opcion por pagar al destino seleccionado codigo envío: ')
        msg += reference || 'Sin Id Pedido'
        super(msg)
      end
    end

    class ErrorNotCourierDestinyAvailable < CourierError
      attr_reader :reference
      def initialize(reference = '', msg = 'No podremos entregar los siguientes pedidos a destino dado que nuestros couriers no llegan, los pedidos son: ')
        msg += reference || 'Sin Id Pedido'
        super(msg)
      end
    end

    class ErrorFulfillmentDeliveryDestiny < CourierError
      attr_reader :reference
      def initialize(reference = '', msg = 'Debes seleccionar las opciones de destino correspondientes a Fulfillment Delivery para el envio: ')
        msg += reference || 'Sin Id Pedido'
        super(msg)
      end
    end

  end
end
