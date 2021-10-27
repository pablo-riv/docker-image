require 'holidays/core_extensions/date'

class Date
  include Holidays::CoreExtensions::Date
  years = []
  Date.new(2017).year.upto(Date.current.year) do |year|
    years << "#{Rails.root}/lib/data/holidays/definitions/#{year}/cl.yaml"
  end
  Holidays.load_custom(years)
  def is_weekend?
    [0, 6, 7].include?(wday)
  end
end
