class AccomplishmentService
  include HTTParty
  BASE_URI = Rails.configuration.statuses_endpoint

  attr_accessor :attributes, :errors

  def initialize(attributes)
    @attributes = attributes
    @errors = []
  end

  def process
    orders =
      if company.platform_version == 2
        OrderService.where(_id: packages.pluck(:mongo_order_id))
      else
        Order.where(package_id: packages.pluck(:id))
      end
    packages.each do |package|
      puts package.id
      check = check_format(package) || tracking_data(package)
      accomplishment_params = { client_preparation_accomplishment: company.platform_version == 2 ? client_preparation(package, orders) : suite_client_preparation(package, orders),
                                hero_pickup_accomplishment: hero_pickup(package, check),
                                first_mile_accomplishment: first_mile(package, check),
                                delivery_accomplishment: delivery(package, check) }
      data = calculate_total(accomplishment_params, package)
      accomplishment = Accomplishment.find_or_create_by(package_id: package.id)
      accomplishment.update(data)
    end
  rescue StandardError => e
    puts "error: #{e.message} \n #{e.backtrace}"
  end

  private

  def packages
    @attributes[:packages]
  end

  def company
    @attributes[:company]
  end

  def tracking_data(package)
    return unless package.tracking_number.present?

    account = package.company.current_account
    response = HTTParty.get("#{BASE_URI}/trackings/number/#{package.tracking_number}", { verify: false,
                                                                                         headers: { 'X-Shipit-Email' => account.email,
                                                                                                    'X-Shipit-Access-Token' => account.authentication_token,
                                                                                                    'Accept' => 'application/vnd.shipit.v4',
                                                                                                    'Content-Type' => 'application/json' } })
    check_date(response['data']['statuses']) if response['data']
  end

  def check_date(statuses)
    in_route = statuses.select { |status| status['generic_status'] == 1 }
    return unless in_route.present?

    {
      in: in_route.last['created_at'],
      out: in_route.first['created_at']
    }
  end

  def check_format(package)
    return unless package.check.present?

    {
      in: package.in_created_at,
      out: package.out_created_at
    }
  end

  def suite_client_preparation(package, orders)
    order = orders.find_by(package_id: package.id)
    cutting_time = CuttingHours::Generator.new(model: company).calculate_cutting_hour.to_time.hour
    return true if order.blank?

    if order.created_at < order.created_at.change(hour: cutting_time)
      return package.created_at < order.created_at.change(hour: cutting_time)
    end

    package.created_at <= 1.business_days.after(order.created_at.change(hour: cutting_time))
  rescue StandardError => e
    puts "error: #{e.message} \n #{e.backtrace}"
  end

  def client_preparation(package, orders)
    order = orders.where(_id: package.mongo_order_id).first
    return true if package.mongo_order_id.blank?
    return false if order.blank?

    if order.day < order.day.change(hour: 14)
      return true if package.created_at < order.day.change(hour: 14)

      return false
    end
    package.created_at <= 1.business_days.after(order.created.change(hour: 14))
  rescue StandardError => e
    puts "error: #{e.message} \n #{e.backtrace}"
  end

  def hero_pickup(package, check)
    return if @fulfillment
    return false if check.blank? || check[:in].blank?
    return true if package.created_at.to_date == check[:in].to_date

    1.business_days.after(package.created_at).to_date <= check[:in].to_date
  end

  def first_mile(package, check)
    return false if check.blank?

    !check[:out].blank? && !package.tracking_number.blank? && !check[:in].blank? && check[:in].to_date == check[:out].to_date
  rescue StandardError => e
    puts "error: #{e.message} \n #{e.backtrace}"
  end

  def delivery(package, check)
    check.present? ? calculate_delivery(package, check[:out]) : false
  end

  def calculate_delivery(package, check)
    return false if package.delivery_time.blank? || package.courier_status_updated_at.blank? || package.delayed || check.blank?

    if check.to_date == package.courier_status_updated_at.to_date
      true
    else
      package.delivery_time.to_i.business_days.after(check.to_date) <= package.courier_status_updated_at.to_date
    end
  rescue StandardError => e
    puts "error: #{e.message} \n #{e.backtrace}"
  end

  def calculate_total(accomplishment_params, package)
    result = accomplishment_params[:delivery_accomplishment] && accomplishment_params[:first_mile_accomplishment] && accomplishment_params[:client_preparation_accomplishment]
    result &&= accomplishment_params[:hero_pickup_accomplishment] unless @fulfillment
    accomplishment_params[:total_accomplishment] = package.status == 'delivered' ? result : nil
    accomplishment_params
  end
end
