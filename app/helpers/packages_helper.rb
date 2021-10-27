module PackagesHelper
  def current_status_for(package)
    status_info = status_name(package.sub_status || package.status, package.courier_for_client)
    content_tag(:span, status_info[:message], class: "label #{status_info[:class]}", data: { toogle: 'tooltip' }, 'data-original-title' => status_info[:message], 'data-placement' => 'top', 'data-toggle' => 'tooltip', 'title' => package.try(:courier_status))
  end

  def alert_status_for(package)
    status = status_name(package.sub_status || package.status, package.courier_for_client)
    content_tag(:div, '', role: 'alert', class: "alert #{status[:class]} text-white mb-0", data: { toogle: 'tooltip' }, 'data-original-title' => status[:message], 'data-placement' => 'top', 'data-toggle' => 'tooltip', 'title' => package.try(:courier_status)) do
      content_tag(:h1, status[:message], class: 'text-center text-white fw-900 m-0')
    end
  end

  def status_name(status, courier = nil)
    case status
    when 'created' then { message: I18n.t('activerecord.attributes.package.statuses.created'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'in_preparation' then { message: I18n.t('activerecord.attributes.package.statuses.in_preparation'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'requested' then { message: I18n.t('activerecord.attributes.package.statuses.requested'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'retired_by' then { message: I18n.t('activerecord.attributes.package.statuses.retired_by'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'received_for_courier' then { message: "#{I18n.t('activerecord.attributes.package.statuses.received_for_courier')}#{" #{courier.capitalize}" if courier}", class: 'status_received_for_courier', icon_color: 'icon_in_preparation' }
    when 'in_route' then { message: I18n.t('activerecord.attributes.package.statuses.in_route'), class: 'route', icon_color: 'icon_in_route' }
    when 'delivered' then { message: I18n.t('activerecord.attributes.package.statuses.delivered'), class: 'delivery', icon_color: 'icon_delivered' }
    when 'failed' then { message: I18n.t('activerecord.attributes.package.statuses.failed'), class: 'fail', icon_color: 'icon_failed' }
    when 'by_retired' then { message: I18n.t('activerecord.attributes.package.statuses.by_retired'), class: 'by-retired', icon_color: 'icon_by_retired' }
    when 'other' then { message: I18n.t('activerecord.attributes.package.statuses.other'), class: 'other', icon_color: 'icon_other' }
    when 'to_marketplace' then { message: I18n.t('activerecord.attributes.package.statuses.to_marketplace'), class: 'other', icon_color: 'icon_other' }
    when 'pending' then { message: I18n.t('activerecord.attributes.package.statuses.pending'), class: 'other', icon_color: 'icon_other' }
    when 'indemnify' then { message: I18n.t('activerecord.attributes.package.statuses.indemnify'), class: 'indemnify', icon_color: 'icon_indemnify' }
    when 'ready_to_dispatch' then { message: I18n.t('activerecord.attributes.package.statuses.ready_to_dispatch'), class: 'process', icon_color: 'icon_ready_to_dispatch' }
    when 'dispatched' then { message: I18n.t('activerecord.attributes.package.statuses.dispatched'), class: 'process', icon_color: 'dispatched' }
    when 'at_shipit' then { message: I18n.t('activerecord.attributes.package.statuses.at_shipit'), class: 'at_shipit', icon_color: 'icon_at_shipit' }
    when 'returned' then { message: I18n.t('activerecord.attributes.package.statuses.returned'), class: 'returned', icon_color: 'icon_returned' }

    when 'first_closed_address' then { message: I18n.t('activerecord.attributes.package.statuses.first_closed_address'), class: 'status_first_closed_address', icon_color: 'status_first_closed_address' }
    when 'second_closed_address' then { message: I18n.t('activerecord.attributes.package.statuses.second_closed_address'), class: 'status_second_closed_address', icon_color: 'status_second_closed_address' }
    when 'back_in_route' then { message: I18n.t('activerecord.attributes.package.statuses.back_in_route'), class: 'status_back_in_route', icon_color: 'status_back_in_route' }
    when 'incomplete_address' then { message: I18n.t('activerecord.attributes.package.statuses.incomplete_address'), class: 'status_incomplete_address', icon_color: 'status_incomplete_address' }
    when 'unexisting_address' then { message: I18n.t('activerecord.attributes.package.statuses.unexisting_address'), class: 'status_unexisting_address', icon_color: 'status_unexisting_address' }
    when 'reused_by_destinatary' then { message: I18n.t('activerecord.attributes.package.statuses.reused_by_destinatary'), class: 'status_reused_by_destinatary', icon_color: 'status_reused_by_destinatary' }
    when 'unkown_destinatary' then { message: I18n.t('activerecord.attributes.package.statuses.unkown_destinatary'), class: 'status_unkown_destinatary', icon_color: 'status_unkown_destinatary' }
    when 'unreachable_destiny' then { message: I18n.t('activerecord.attributes.package.statuses.unreachable_destiny'), class: 'status_unreachable_destiny', icon_color: 'status_unreachable_destiny' }
    when 'strayed' then { message: I18n.t('activerecord.attributes.package.statuses.strayed'), class: 'status_strayed', icon_color: 'status_strayed' }
    when 'damaged' then { message: I18n.t('activerecord.attributes.package.statuses.damaged'), class: 'status_damaged', icon_color: 'status_damaged' }
    when 'indemnify_out_of_date' then { message: I18n.t('activerecord.attributes.package.statuses.indemnify_out_of_date'), class: 'status_indemnify_out_of_date', icon_color: 'status_indemnify_out_of_date' }
    when 'failed_by_retired' then { message: I18n.t('activerecord.attributes.package.statuses.failed_by_retired'), class: 'failed', icon_color: 'status_failed' }
    when 'returned_failed' then { message: I18n.t('activerecord.attributes.package.statuses.returned_failed'), class: 'failed', icon_color: 'status_failed' }
    when 'returned_in_route' then { message: I18n.t('activerecord.attributes.package.statuses.returned_in_route'), class: 'in_route', icon_color: 'status_in_route' }
    when 'fulfillment' then { message: I18n.t('activerecord.attributes.package.statuses.fulfillment'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'fulfillment_open' then { message: I18n.t('activerecord.attributes.package.statuses.fulfillment_open'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'fulfillment_pending' then { message: I18n.t('activerecord.attributes.package.statuses.fulfillment_pending'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'fulfillment_success' then { message: I18n.t('activerecord.attributes.package.statuses.fulfillment_success'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'fulfillment_partial' then { message: I18n.t('activerecord.attributes.package.statuses.fulfillment_partial'), class: 'process', icon_color: 'icon_in_preparation' }
    when 'crossdock' then { message: I18n.t('activerecord.attributes.package.statuses.crossdock'), class: 'process', icon_color: 'icon_in_preparation' }
    else
      { message: 'Sin Estado Asignado', class: 'fail', icon_color: 'icon_failed' }
    end
  end

  def price_for_client(package, price)
    package.is_paid_shipit ? 0 : price
  end

  def commune(package)
    return package.address.try(:commune).try(:name).try(:titleize) || 'Sin Comuna'
  end

  def months_range_options
    ((Date.current - 1.year)..Date.current).map {|d| [I18n.l(d, format: '%B %Y'), d.strftime('%m/%Y')]}.uniq.reverse
  end

  def statuses_format
    [['Todos', ''],
     [I18n.t('activerecord.attributes.package.statuses.created'), 'created'],
     [I18n.t('activerecord.attributes.package.statuses.in_preparation'), 'in_preparation'],
     [I18n.t('activerecord.attributes.package.statuses.in_route'), 'in_route'],
     [I18n.t('activerecord.attributes.package.statuses.delivered'), 'delivered'],
     [I18n.t('activerecord.attributes.package.statuses.dispatched'), 'dispatched'],
     [I18n.t('activerecord.attributes.package.statuses.by_retired'), 'by_retired'],
     [I18n.t('activerecord.attributes.package.statuses.failed'), 'failed'],
     [I18n.t('activerecord.attributes.package.statuses.at_shipit'), 'at_shipit'],
     [I18n.t('activerecord.attributes.package.statuses.returned'), 'returned']]
  end

  def grouped_packages_by_status(packages, per_status: {})
    packages = packages.group_by(&:status).slice('created', 'in_preparation', 'in_route', 'dispatched', 'ready_to_dispatch', 'failed', 'by_retired')
    packages.map do |status, list|
      list = list.select do |pack|
        !pack.statuses_condition
      end
      per_status[status] = list
    end
    per_status
  end

  def package_url_permited_params(*args)
    args.each do |specific_param|
      params[specific_param.keys[0]] = specific_param.values[0]
    end
    params.permit(:from_courier, :from_date, :to_date, :by_status, :with_series, :email_to)
  end

  def package_to_edit_format(package)
    package.serializable_hash(include: { address: {include: { commune: {} } } })
  end

  def kind_of_price_label(package, kind_of_price = '')
    package.estimated_price? ? I18n.t("activerecord.attributes.package.estimated_#{kind_of_price}") : I18n.t("activerecord.attributes.package.#{kind_of_price}")
  end
end
