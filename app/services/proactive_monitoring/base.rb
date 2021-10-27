module ProactiveMonitoring
  class Base
    def initialize(package, delivery_date, organization_id)
      @deadline = { deadline_expired: false, motive: nil }
      @delivery_date = delivery_date
      @package = package
      @organization_id = organization_id
    end

    def deadline_expired
      deadline_operation_date
      return @deadline if @deadline[:deadline_expired]

      deadline_delivery_date
      return @deadline if @deadline[:deadline_expired]

      deadline_status_updated
      return @deadline if @deadline[:deadline_expired]

      deadline_first_response
      return @deadline if @deadline[:deadline_expired]

      deadline_solved_managment
      return @deadline if @deadline[:deadline_expired]

      false
    end

    private

    def deadline_status_updated
      return if @package.shipit_status_updated_at.nil?

      @deadline[:deadline_expired] = (@package.shipit_status_updated_at + @engagement_rules.without_movement.days) <= Date.current
      return unless @deadline[:deadline_expired]

      @deadline[:motive] = 'Plazo desde el último movimiento de estado cumplido'
    end

    def deadline_delivery_date
      @deadline[:deadline_expired] = @delivery_date < Date.current
      return unless @deadline[:deadline_expired]

      @deadline[:motive] = 'Plazo de entrega cumplido'
    end

    def deadline_first_response
      supports = @package.supports.where(requester_type: 'courier')
                         .where.not('LOWER(status) IN (?)', %w[solved resuelto])
      return if supports.size.zero?

      support = supports.order(:updated_at).last
      courier_messages = support.messages.select { |m| m['organization_id'] == @organization_id }
      return if courier_messages.size.zero?
      return if courier_messages.last['created_at'].nil?

      @deadline[:deadline_expired] = (courier_messages.last['created_at'].to_date + @engagement_rules.unanswered.days) > Date.current
      return unless @deadline[:deadline_expired]

      @deadline[:motive] = 'Plazo de primera respuesta cumplido'
    end

    def deadline_solved_managment
      supports = @package.supports.where(requester_type: 'courier')
                         .where.not('LOWER(status) IN (?)', %w[solved resuelto])
      return if supports.size.zero?

      supports!.order(:updated_at)
      @deadline[:deadline_expired] = (support.last.updated_at + @engagement_rules.without_management.days) > Date.current
      return unless @deadline[:deadline_expired]

      @deadline[:motive] = 'Plazo de gestión cumplido'
    end

    def deadline_operation_date
      return unless @package.delivery_time.present?

      checkout = @package.check?('out')
      return unless checkout.present?

      estimated_delivery = checkout ? @package.delivery_time.to_i.business_days.after(checkout.to_date) : @package.delivery_time.to_i.business_days.after(@package.created_at)
      return if estimated_delivery < Date.current

      @deadline[:expired] = (Date.current - estimated_delivery).to_i > @engagement_rules.max_date_for_delivery
      return unless @deadline[:deadline_expired]

      @deadline[:motive] = 'Envío atrasado'
    end
  end
end
