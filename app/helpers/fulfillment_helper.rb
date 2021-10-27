module FulfillmentHelper
  def company_skus(company_id)
    FulfillmentService.by_client(company_id)
  end

  def named_inventory_activity_type(ia_type)
    case ia_type
    when 1 then 'Egreso'
    when 2 then 'Ingreso'
    when 3 then 'Retiro'
    end
  end

  def total_stock(charge)
    if charge < 15_000
      content_tag(:span, number_to_currency(15_000), data: { toggle: 'tooltip' }, title: "Monto real: #{number_to_currency(charge)}", class: 'text-red')
    else
      number_to_currency(charge)
    end
  end

  def total_charges(stock_charge, total_charge)
    if stock_charge < 15_000
      content_tag(:span, number_to_currency(sum_charges(stock_charge, total_charge)), data: { toggle: 'tooltip' }, title: "Monto real: #{total_warehouse_shipments(total_charge)}", class: 'text-red')
    else
      number_to_currency(total_warehouse_shipments(total_charge))
    end
  end

  def sum_charges(stock_charge, total_charge)
    if stock_charge < 15_000
      15_000 + sum_warehouse(total_charge) + sum_shipments(total_charge) + total_charge[:recurrent_charge] + total_charge[:premium] - stock_charge.round
    else
      total_warehouse_shipments(total_charge)
    end
  end
end
