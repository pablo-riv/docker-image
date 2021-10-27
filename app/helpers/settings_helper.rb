module SettingsHelper
  def get_template_for(service)
    case service.id
    when 1 then 'shared/configure_opit'
    when 2 then 'shared/configure_fullit'
    when 3 then 'shared/configure_pick_and_pack'
    when 4 then 'shared/configure_fulfillment'
    when 5 then 'shared/configure_delivery'
    end
  end

  def style_color(courier)
    case courier
    when 'cxp' then 'warning'
    when 'stk' then 'success'
    when 'cc' then 'danger'
    end
  end

  def get_name_for(service)
    case service.name
    when 'opit' then 'Opit'
    when 'fullit' then 'Integraciones'
    when 'pp' then 'Pick & Pack'
    when 'fulfillment' then 'Fulfillment'
    when 'sd' then 'Shipit Delivery'
    end
  end

  def icon_for(service)
    case service.name
    when 'opit' then 'i-op'
    when 'fullit' then 'fas fa-cogs'
    when 'pp' then 'i-pp'
    when 'fulfillment' then 'i-ff'
    end
  end

  def values_for(seller, field)
    seller[seller.keys.first][field] unless seller.blank?
  end
end
