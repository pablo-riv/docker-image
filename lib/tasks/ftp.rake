require 'net/ftp'
require 'open-uri'
require 'csv'

namespace :ftp do

  desc 'Add changes for FTP'
  task create_csv_mc: :environment do

    packages = Package.where(id: [111608])
    puts "creating csv"
    packages.each do |package|
      CSV.open("#{Rails.root}/public/PID2_IDA#{package.id}.csv", 'w', col_sep: ',') do |csv|
      packages.each do |package|
        header = ['Fecha de creacion',
                  'Hora de creacion',
                  'Identificacion linea',
                  'Codigo de Cliente',
                  'N de Pedido',
                  'Transaccion pedido',
                  'Codigo destino',
                  'Codigo de Producto',
                  'Descripcion de Producto',
                  'Cantidad',
                  'Local',
                  'Bodega',
                  'Estado',
                  'Lote',
                  'Picking o Ruta',
                  'Fecha de Despacho',
                  'Modo de entrega',
                  'Direccion Cliente Destino',
                  'Ciudad Cliente Destino',
                  'Comuna Cliente Destino',
                  'Rut Cliente Destino',
                  'Nombre Cliente Destino',
                  'Observaciones']
        count = 0
        package.inventory_activity['inventory_activity_orders_attributes'].each do |order|
          count += 1
          csv << [package.created_at.to_date.strftime('%d/%m/%Y'),
                  package.created_at.to_date.strftime('%H:%M:%S'),
                  count,
                  '3',
                  package.reference,
                  'PV',
                  '3',
                  FulfillmentService.sku(order['sku_id'].to_i)['name'] ? FulfillmentService.sku(order['sku_id'].to_i)['name'] : 'no hay nombre',
                  '',
                  order['amount'].to_i,
                  '',
                  '100',
                  '',
                  '',
                  '',
                  package.created_at.to_date.strftime('%d/%m/%Y'),
                  'D',
                  "#{package.address.street} #{package.address.number}",
                  package.address.commune.region.name,
                  package.address.commune.name,
                  '',
                  package.full_name,
                  package.comments]
        end
        puts "creating #{package.id} csv"
      end
    end

    end
  end
end
