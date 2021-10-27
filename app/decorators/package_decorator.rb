class PackageDecorator < Draper::Decorator
  delegate_all

  def is_payable
    object.is_payable ? 'Si' : 'No'
  end

  def is_returned
    object.is_returned ? 'Si' : 'No'
  end

  def is_paid_shipit
    object.is_paid_shipit ? 'Si' : 'No'
  end

  def courier_selected
    object.courier_selected ? 'Si' : 'No'
  end

  def created_at
    object.created_at.try(:strftime, '%d-%m-%Y %H:%M') || ''
  end

  def operation_date
    object.operation_date.try(:strftime, '%d-%m-%Y') || ''
  end

  def courier_status_updated_at
    object.courier_status_updated_at.try(:to_datetime).try(:strftime, '%d-%m-%Y %H:%M') || ''
  end

  def shipit_status_updated_at
    object.shipit_status_updated_at.try(:strftime, '%d-%m-%Y %H:%M') || ''
  end

  def full_name
    object.full_name.titleize
  end
end
