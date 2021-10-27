class CheckAreaBranchOfficeJob < ApplicationJob
  queue_as :default

  def perform(branch_office)
    company = branch_office.company
    address = branch_office.full_address
    # MONKEY PATCH TO HELP OPS TEAM TO PREVENT OVERWRITE
    # DEFAULT AREA TO CARRIER PICKUP
    return if branch_office.location.area_id == 188

    latlng = Geocoder.coordinates(address)
    puts "latlng: #{latlng}".green.swap
    raise "Latitud y/o Longitud no encontrada para la dirección: #{address}" unless latlng.present?

    areas = Area.all.reject { |area| area.coords.blank? || area.coords.first['latitude'].blank? }
    area = areas.select { |area| RaycastServices::Calc.contains?(area.formated_coords, latlng.first, latlng.second) == 1 }.first
    raise 'No se pudo ubicar al cliente dentro de nuestras areas definidas.' if area.blank?

    heros = area.heros
    raise "No se pudo asignar heroe dado que el area a asignar (#{area.id} #{area.name}) no posee heroe." if heros.blank?

    hero = heros.distinct.first
    type = branch_office.location.update_columns(area_id: area.id, hero_id: hero.id) ? 'automatica' : 'manual'
    branch_office.update_latitude_and_longitude_to_origin(coords: { latitude: latlng.first, longitude: latlng.second })
    NewUserMailer.area_assign(company, branch_office, type).deliver
    Publisher.publish('reasigned_hero', { hero: hero, branch_offices: [branch_office.id] }.to_json)
  rescue StandardError => e
    Slack::Ops.new({}, {}).alert('', "CheckAreaBranchOfficeJob en Clientes: 23\nCliente: #{company.name} id: #{company.id} no pudo asignar AREA\n#{e.message}\nBUGTRACE: #{e.backtrace.first(2).join("\n")}")
    NewUserMailer.area_error(company, branch_office).deliver if area.blank?
    NotifyMailer.area_not_assign(company, branch_office, area).deliver if heros.blank? || area.blank?
  end
end
