crumb :root do
  link 'Inicio', root_path
end

crumb :error do
  link 'Error', '#'
  parent :root
end

crumb :instructions do
  link 'Instrucciones', instructions_path
end

crumb :packages do
  link 'Historial de Envíos', packages_path
end

crumb :monitor do
  link 'Monitor', monitor_packages_path
end

crumb :branch_offices do
  link 'Puntos de retiro Marketplace', branch_offices_path
end

crumb :analytics do
  link 'Analíticas', analytics_path
end

crumb :debtors do
  if params[:controller] == 'debtors'
    link I18n.t('debtors.link'), debtors_path
  end
  if params[:controller] == 'headquarter/debtors'
    link I18n.t('debtors.link'), headquarter_debtors_path
  end
end

crumb :package do |package|
  case action_name
  when 'new' then link 'Nuevo Envío', new_package_path
  when 'show' then link package.reference, package_path(package.id)
  when 'edit' then link 'Editar ' + package.reference, edit_package_path
  when 'return' then link 'Devolución ' + package.reference, new_returns_packages_path(package.id)
  when 'returns' then link 'Devoluciones', returns_packages_path
  end
  parent :packages
end

crumb :sellings do
  link 'Mis ventas', integrations_path
end

crumb :integrations do
  link 'Integraciones', my_integrations_settings_path
end

crumb :services do
  link 'Servicios', services_path
end

crumb :settings do |service, setting|
  link service.real_name, service_settings_path(service.id, setting.id)
  parent :services
end

crumb :general_settings do
  link I18n.t('menu.services'), settings_path
end

crumb :config_couriers do
  link 'Couriers', config_couriers_settings_path
end

crumb :config_printers do
  link 'Impresión', config_printers_settings_path
end

crumb :packings_on_settings do
  link "Empaques", settings_path
  parent :general_settings
end

crumb :packing_on_settings do
  link "#{params[:id]}", packing_path(params[:id])
  parent :packings_on_settings
end

crumb :new_packing do
  link "Nuevo", new_packing_path
  parent :packings_on_settings
end

crumb :products_on_settings do
  link "Productos", settings_path
  parent :general_settings
end

crumb :product_on_settings do
  link "#{params[:id]}", product_path(params[:id])
  parent :products_on_settings
end

crumb :new_product do
  link "Nuevo", new_product_path
  parent :products_on_settings
end

crumb :labels do
  link I18n.t('menu.labels'), labels_path
end


crumb :labels_pack do
  link I18n.t('menu.labels_pack'), pack_labels_path
end

crumb :helps do
  link I18n.t('menu.support'), helps_path
end

crumb :notifications do
  link I18n.t('menu.notification'), notifications_path
end

crumb :edit_notification do
  link 'Editar email', '#'
  parent :notifications
end

crumb :settings_api do
  link 'Configuración Api', api_settings_path
end

crumb :charges do
end

crumb :charges_fulfillment do
  link 'Fulfillment', fullfilment_charges_path
  parent :charges
end

crumb :charges_fulfillment_by_month do
  link l(Date.parse("#{params[:year]}/#{params[:month]}"), format: '%B %Y'), fullfilment_by_month_charges_path(params[:year], params[:month])
  parent :charges_fulfillment
end

crumb :charges_fulfillment_by_month_packages do
  link 'Envíos', fulfillment_month_packages_charges_path(params[:year], params[:month])
  parent :charges_fulfillment_by_month
end

crumb :charges_fulfillment_by_day_packages do
  link 'Envíos', fulfillment_month_packages_charges_path(params[:year], params[:month], params[:day])
  parent :charges_fulfillment_by_month
end

crumb :charges_fulfillment_by_month_details do
  link 'Detalles', fullfilment_by_month_details_charges_path(params[:year], params[:month])
  parent :charges_fulfillment_by_month
end

crumb :charges_pp do
  link 'Pick & Pack', pickandpack_charges_path
  parent :charges
end

crumb :charges_pp_by_month do
  link l(Date.parse("#{params[:year]}/#{params[:month]}"), format: '%B %Y'), pickandpack_by_month_charges_path(params[:year], params[:month])
  parent :charges_pp
end

crumb :charges_pp_extras_by_month do
  link 'Extras', pickandpack_by_month_charges_path(params[:year], params[:month])
  parent :charges_pp_by_month
end

crumb :charges_fines do
  link 'Cobros por cancelación', fines_charges_path
  parent :charges
end

crumb :charges_parking_fines do
  link 'Estacionamientos', parking_charges_path
  parent :charges
end

crumb :charges_discounts do
  link 'Reembolsos', parking_charges_path
  parent :charges
end

crumb :budgets do
  link 'Cotizador', budgets_path
end

crumb :fulfillment do
  link 'Fulfillment'
end

crumb :fulfillment_receipts do
  link 'Ingresos', receipt_fulfillment_index_path
  parent :fulfillment
end

crumb :fulfillment_outs do
  link 'Egresos', out_fulfillment_index_path
  parent :fulfillment
end

crumb :fulfillment_inventory do
  link 'Inventario', inventory_fulfillment_index_path
  parent :fulfillment
end

crumb :sku do |sku|
  link "SKU #{sku['name']}"
  parent :fulfillment
end

crumb :inventory_activity do |type, date|
  link "#{type} #{date}"
  parent :fulfillment
end
