class OrderDecorator < Draper::Decorator
  delegate_all

  def destiny
    name = object.destiny['full_name']
    object.destiny['full_name'] = name.present? ? name.titleize : ''
    object.destiny
  end
end
