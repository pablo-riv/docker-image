class CuttingHourDecorator < ApplicationDecorator
  delegate_all

  def by_service(service = :pick_and_pack)
    time = object.by_service(service)
    hour = time.to_i
    min = (time - hour) * 60
    Time.zone.now.change(hour: hour, min: min.round).strftime('%H:%M')
  end
end
