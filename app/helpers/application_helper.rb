module ApplicationHelper
  def data_turbolinks
    { data: { turbolinks: false } }
  end

  def rollout(feature)
    ($rollout.active? feature, current_account) || ($rollout.active? :admin, current_account)
  end

  def get_full_name
    current_account.nil? ? '' : current_account.full_name
  end

  def get_email
    current_account.email
  end

  def has_all_services?(account)
    services = account.entity.specific.services.count
    service_quantity = Service.count
    services == service_quantity ? true : false
  rescue => e
    puts e.message.to_s
    return false
  end

  def fullit?(account)
    return unless account_signed_in?

    @setting_fullit = account.entity_specific.settings.fullit(account.entity_specific.id)
    @setting_fullit unless @setting_fullit.nil?
  end

  def sellers?(account)
    return unless account_signed_in?

    @setting_fullit = account.entity_specific.settings.fullit(account.entity_specific.id)
    has_sellers = false
    @setting_fullit.configuration['fullit']['sellers'].each do |seller|
      has_sellers = true unless seller.values[0]['client_id'].blank?
    end
    has_sellers
  end

  def ship_type(fulfillment)
    fulfillment ? 'Ingresar un Pedido' : 'Solicita un retiro'
  end

  def fulfillment?(account)
    return unless account_signed_in?

    @setting_fullfillment = account.entity_specific.settings.fulfillment(account.entity_specific.id)
    @setting_fullfillment unless @setting_fullfillment.nil?
  end

  def courier_icon(courier_for_client)
    size =
      case courier_for_client.try(:downcase)
      when 'chilexpress', 'correoschile' then 110
      when 'starken', 'fulfillment delivery' then 80
      when 'shipit' then 70
      else
        110
      end
    courier_for_client.blank? ? 'Sin Courier' : image_tag("https://s3-us-west-2.amazonaws.com/couriers-shipit/#{courier_for_client.try(:downcase)}.png", width: size)
  end

  def currency_price(price)
    if price.zero? || price.empty? || price.nil?
      '0 CLP'
    else
      "#{price} CLP"
    end
  end

  def courier_tracking_link(package)
    return 'Sin tracking' if package.tracking_number.blank?

    url = "https://seguimiento.shipit.cl/statuses?number=#{package.tracking_number}"
    !package.tracking_number.present? ? package.tracking_number : link_to(package.tracking_number, url, target: '_blank')
  end

  def week_day(day)
    return 'Sin Información' if day.blank?

    case day.capitalize
    when 'Monday' then 'Lunes'
    when 'Tuesday' then 'Martes'
    when 'Wednesday' then 'Miercoles'
    when 'Thursday' then 'Jueves'
    when 'Friday' then 'Viernes'
    when 'Saturday' then 'Sabado'
    when 'Sunday' then 'Domingo'
    end
  end

  def fill_color(controller)
    if controller.include?('setup/companies')
      ['s-1', 's-3-off', 's-4-off']
    elsif controller.include?('setup/people')
      ['s-1', 's-3', 's-4-off']
    else
      ['s-1', 's-3', 's-4']
    end
  end

  def active_class_for(section)
    'active' if case section
                when 'dashboard' then params[:controller] == 'public' && params[:action] == 'dashboard'
                when 'packages' then params[:controller] == 'packages' && params[:action] == 'index'
                when 'monitor' then params[:controller] == 'packages' && params[:action] == 'monitor'
                when 'services' then params[:controller] == 'services' && params[:action] == 'index'
                when 'settings' then params[:controller] == 'settings' && params[:action] == 'index'
                when 'integrations' then params[:controller] == 'integrations' && params[:action] == 'index'
                when 'config_integrations' then params[:controller] == 'settings' && params[:action] == 'my_integrations'
                when 'budgets' then params[:controller] == 'budgets' && params[:action] == 'index'
                when 'charges' then params[:controller] == 'charges'
                when 'branch_offices' then params[:controller] == 'branch_offices'
                when 'api' then params[:controller] == 'settings' && params[:action] == 'api'
                when 'integrations' then params[:controller] == 'settings' && params[:action] == 'edit' && params[:service_id] == 2
                when 'headquarter_dashboard' then params[:controller] == 'headquarter/public' && params[:action] == 'dashboard'
                when 'headquarter_packages' then params[:controller] == 'headquarter/packages' && params[:action] == 'index'
                when 'notifications' then params[:controller].include?('notifications')
                when 'support' then params[:controller].include?('support')
                when 'helps' then params[:controller].include?('helps')
                when 'analytics' then params[:controller].include?('analytics')
                when 'returns' then params[:controller].include?('returns')
                when 'config_couriers' then request.path.include?('config_couriers')
                when 'config_printers' then request.path.include?('config_printers')
                end
  end

  def fullit
    company = current_account.entity_specific
    Setting.fullit(company.id).id
  end

  def sent_email?(package)
    company = package.branch_office.company
    notification = Setting.notification(company.id).configuration['notification']
    return without_notification_to_buyer unless notification['buyer'].present?
    states = notification['buyer']['mail']['state']
    popover = ''
    states.each do |key, value|
      (popover += '' && next) unless value
      state = status_name(key)
      content =
        if package.alerts.try(:delivered, key)
          state
        else
          { message: state[:message], class: 'grey', icon_color: 'icon_grey' }
        end
      popover += "#{content[:message]}: &nbsp;&nbsp;&nbsp; <i class='fas fa-envelope-open #{content[:icon_color]}'></i><br/>"
    end
    content_tag(:span, '',
                class: "fas fa-envelope #{status_name(package.status)[:icon_color]} pointer operation-help",
                data: { container: 'body',
                        toggle: 'popover',
                        placement: 'right',
                        content: popover,
                        html: 'true',
                        animation: 'true'},
                title: 'Correos enviados')
  end

  def without_notification_to_buyer
    content_tag(:span, '', class: 'fas fa-exclamation-triangle pointer operation-help icon_failed', data: { container: 'body', toggle: 'popover', placement: 'right', content: 'Sin configuración de notificaiones a comprador', animation: 'true'}, title: '¡Importante!')
  end

  def convert_tag(tags, text, attr)
    return '' unless text.present?

    tags.each do |tag|
      next unless text.include?("#{tag[0]}")

      text =
        if attr.class == Package
          case tag[0]
          when 'buyer_name' then text.gsub('{buyer_name}', attr.full_name.try(:titleize))
          when 'tracking_number' then text.gsub('{tracking_number}', attr.tracking_number)
          when 'package_reference' then text.gsub('{package_reference}', attr.reference.try(:upcase))
          when 'package_courier' then text.gsub('{package_courier}', attr.courier_for_client.try(:titleize))
          else
            ''
          end
        else
          text.gsub("{#{tag[0]}}", attr.capitalize)
        end
    end

    text.html_safe
  end

  def notification_emails(account)
    if !account.current_company.entity.email_notification.blank?
      account.current_company.entity.email_notification
    elsif !account.current_company.entity.email_contact.blank?
      account.current_company.entity.email_contact
    else
      account.email
    end
  end

  def charges_link_type
    fulfillment?(current_account)
    year = Date.current.year
    @setting_fullfillment.present? ? fullfilment_charges_path(year: year) : pickandpack_charges_path(year: year)
  end

  def image_hero(hero)
    hero.identity_image.url(:medium).include?('missing') ? 'https://s3-us-west-2.amazonaws.com/shipit-platform/ala.png' : @hero.identity_image.url(:medium)
  end

  def avaliable_switch_suite(current_account, suite = false)
    company = current_account.entity_specific
    sellers = Setting.fullit(company.id)
    return suite unless company.fulfillment?

    suite = true unless sellers.active_suite_sellers(sellers.sellers_availables).size.zero?
    suite
  end
end
