module CuttingHours
  module Calculator
    def calculate_days
      date = datetime.to_date
      base_days = calculate_base_days
      date = calculate_date(date, base_days.days)

      while date.holiday?(:custom_cl) || date.is_weekend?
        date = reverse ? date - 1.days : date + 1.days
        base_days += 1
      end
      base_days
    end

    def calculate_cutting_hour
      distribution_center = distribution_center_by_model
      return unless distribution_center.present?

      cutting_hour = distribution_center&.cutting_hour&.decorate&.by_service(find_service)
      time = Time.zone.now.change(hour: cutting_hour.to_time.hour, min: cutting_hour.to_time.min) + @hours_collection.sum(&:to_f).hours
      time.strftime('%H:%M%z')
    end

    private

    def by_service
      model.cutting_hour.by_service(service)
    end

    def calculate_base_days
      reverse || cutting_hour?(datetime, calculate_cutting_hour) ? 1 : 0
    end

    def cutting_hour?(datetime, time_by_service)
      datetime >= "#{datetime.to_date} #{time_by_service}".to_datetime
    end

    def calculate_date(date, base_days)
      reverse || (reverse && current?) ? date - base_days : date + base_days
    end

    def abbreviated
      case service
      when 'pick_and_pack', 'pp' then 'pp'
      when 'fulfillment', 'ff' then 'ff'
      when 'labelling', 'll' then 'll'
      end
    end

    def distribution_center_by_model
      case model.class.name
      when 'Package' then model.branch_office.distribution_center
      when 'Area', 'BranchOffice' then model.distribution_center
      when 'DistributionCenter' then model
      else ::DistributionCenter.default
      end
    end
  end
end
