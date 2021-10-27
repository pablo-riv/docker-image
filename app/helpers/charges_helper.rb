module ChargesHelper
  def date_navigation_links(date)
    prev_link = link_to l(date.prev_month, format: '%B %Y'), fullfilment_by_month_charges_path(date.prev_month.year, date.prev_month.month), data_turbolinks
    next_link = link_to l(date.next_month, format: '%B %Y'), fullfilment_by_month_charges_path(date.next_month.year, date.next_month.month), data_turbolinks
    current = "<strong><span class='tag tag-info'> #{l(date, format: '%B %Y')} </span></strong>".html_safe
    links(prev_link, current, next_link)
  end

  def date_navigation_links_with_details(date)
    prev_link = link_to l(date.prev_month, format: '%B %Y'), fullfilment_by_month_details_charges_path(date.prev_month.year, date.prev_month.month), data_turbolinks
    next_link = link_to l(date.next_month, format: '%B %Y'), fullfilment_by_month_details_charges_path(date.next_month.year, date.next_month.month), data_turbolinks
    current = "<strong><span class='tag tag-info'> #{l(date, format: '%B %Y')} </span></strong>".html_safe
    links(prev_link, current, next_link)
  end

  def navigation_pp_by_year(date)
    prev_link = link_to l(date.prev_year, format: '%Y'), pickandpack_charges_path(year: date.prev_year.year), data_turbolinks
    next_link = link_to l(date.next_year, format: '%Y'), pickandpack_charges_path(year: date.next_year.year), data_turbolinks
    current = "<strong><span class='tag tag-info'> #{l(date, format: '%Y')} </span></strong>".html_safe
    links(prev_link, current, next_link)
  end

  def navigation_ff_by_year(date)
    prev_link = link_to l(date.prev_year, format: '%Y'), fullfilment_charges_path(year: date.prev_year.year), data_turbolinks
    next_link = link_to l(date.next_year, format: '%Y'), fullfilment_charges_path(year: date.next_year.year), data_turbolinks
    current = "<strong><span class='tag tag-info'> #{l(date, format: '%Y')} </span></strong>".html_safe
    links(prev_link, current, next_link)
  end

  def links(prev_link, current, next_link)
    "< #{prev_link} | #{current} | #{next_link} >".html_safe
  end

  def total_warehouse_shipments(data)
    values = data.delete_if { |k, v| k == :id || k == :company_name || k == :total }.values.sum.try(:round)
  end

  def sum_warehouse(data)
    sum_attrs(data[:in].to_f, data[:out].to_f, data[:stock].to_f, data[:others].to_f)
  end

  def sum_shipments(data)
    sum_attrs(data[:shipments].to_f, data[:material_extra].to_f, data[:total_is_payable].to_f)
  end

  def sum_packages_charges(packages, attr)
    (packages.pluck(attr).compact.sum || 0).try(:round)
  end

  def sum_total_packages_charge(packages)
    packages.pluck(:shipping_price, :total_is_payable, :material_extra).reduce(:+).
      compact.each(&:to_f).sum.round
  end

  def sum_attrs(*args)
    args.compact.sum.round
  end
end
