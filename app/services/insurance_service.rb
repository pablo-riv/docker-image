class InsuranceService
  INSURANCE = {
    'default': {
      'min': 70_000,
      'max': 1_000_000,
      'percent': 0.01
    }
  }.with_indifferent_access
  COURIERS = %i[default].freeze

  def initialize(object)
    @object = object
    @errors = []
  end

  def active
    raise unless insurance.update(calculate)
  rescue StandardError => e
    puts e.message.to_s.red.swap
  end

  private

  def calculate
    courier = INSURANCE[courier_name]
    courier_coverage = courier['max'] * courier['percent']
    object = calculate_courier_coverage(insurance.ticket_amount, courier, courier_coverage) if valid? || valid_automatization?

    { price: object[:price].round.to_i,
      extra: object[:valid] && (insurance.extra || automatization['active']) }
  rescue StandardError => _e
    { price: 0, extra: false }
  end

  def valid_automatization?
    %w(sheet massive_form integration).include?(platform) && insurance.ticket_number.present? && insurance.ticket_amount.present? && insurance.detail.present? && (automatization['active'] && insurance.ticket_amount >= automatization['amount'])
  end

  def calculate_courier_coverage(ticket_amount, courier, courier_coverage)
    amount = ticket_amount * courier['percent']
    amount = courier_coverage if amount > courier_coverage

    valid = ticket_amount > courier['min'] && ticket_amount <= courier['max']
    { price: valid ? amount : 0, valid: valid }
  end

  def courier_name
    name = courier_for_client.try(:downcase)
    name.present? && COURIERS.include?(name) ? name : 'default'
  end

  def valid?
    insurance.ticket_number.present? && insurance.ticket_amount.present? && insurance.detail.present? && insurance.extra
  end

  def insurance
    # Validation to prevent rollback in railse when packages are commited
    @object[:insurance] || Insurance.find_or_create_by(package_id: id)
  end

  def id
    @object[:id]
  end

  def courier_for_client
    @object[:courier_for_client]
  end

  def automatization
    @object[:automatization]
  end

  def platform
    @object[:platform]
  end
end
