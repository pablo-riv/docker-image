class Holiday
  def self.today?
    today = Date.today
    civil = Date.civil(today.year, today.month, today.day)
    civil.holiday?(:cl)
  end

  def self.yesterday?
    today = Date.today
    civil = Date.civil(today.year, today.month, today.day)
    yesterday = civil - 1.day
    yesterday.holiday?(:cl)
  end

  def self.calculate_day
    today = Date.today
    yesterday = today - 1.day

    if Holiday.yesterday?
      day = yesterday - 1.day
      day.holiday?(:cl) ? 5 : 1
    end
  end
end
