module Calculator
  module Error
    class CalculatorError < ::StandardError; end

    class UndefinedDestiny < CalculatorError
      def initialize
        super('Comuna de destino no encontrada')
      end
    end

    class CantGetPrice < CalculatorError
      def initialize
        super('No obtuvimos precios bajo los parametros enviados')
      end
    end
  end
end
