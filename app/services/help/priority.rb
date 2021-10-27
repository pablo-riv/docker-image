module Help
  class Priority
    attr_accessor :properties

    def initialize(properties)
      @properties = properties
    end

    def priorize
      values(category, kind, commercial_priority)
    end

    private

    def values(*args)
      case args.sum
      when 70..100 then 'urgent'
      when 50..69  then 'high'
      when 30..49  then 'normal'
      else
        'low'
      end
    end

    def category
      case properties[:category]
      when 'big'    then 25
      when 'medium' then 15
      when 'newbie' then 20
      when 'old'    then 5
      else
        0
      end
    end

    def kind
      case properties[:kind]
      when 'problem'  then 25
      when 'incident' then 15
      when 'question' then 5
      else
        0
      end
    end

    def commercial_priority
      case properties[:priority]
      when 'urgente' then 50
      when 'alta'    then 40
      when 'normal'  then 15
      when 'baja'    then 5
      else
        0
      end
    end

    # unused attr
    def packages_hope
      properties[:packages_hope]
    end

    # unused attr
    def last_month_deliveries
      properties[:last_month_deliveries]
    end
  end
end
