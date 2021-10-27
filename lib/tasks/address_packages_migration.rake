namespace :address_packages_migration do
  desc 'Populate new origins packages table'
  task populate_origin_package: :environment do
    puts '===Migrando origin_packages==='.green.swap
    sql_origin_packages = "
    INSERT INTO origin_packages (commune_id, package_id, full_name, phone,
                                 email, number, street, zip_code, complement,
                                 origin_id, created_at, updated_at)
    SELECT
    communes.id as commune_id,
    packages.id as package_id,
    address_books.full_name as full_name,
    address_books.phone as phone,
    address_books.email as email,
    addresses.number as number,
    addresses.street as street,
    addresses.zip_code as zip_code,
    addresses.complement as complement,
    address_books.addressable_id as origin_id,
    NOW()::timestamp as created_at,
    NOW()::timestamp as updated_at
    FROM
    packages,
    branch_offices,
    companies,
    address_books,
    origins,
    addresses,
    communes
    WHERE
    packages.branch_office_id = branch_offices.id AND
    branch_offices.company_id = companies.id AND
    address_books.company_id = companies.id AND
    address_books.default = true AND
    address_books.addressable_type = 'Origin' AND
    address_books.addressable_id = origins.id AND
    address_books.address_id = addresses.id AND
    addresses.commune_id = communes.id
    ORDER BY packages.id ASC"
    ActiveRecord::Base.connection.execute(sql_origin_packages)
    puts '===Finalizo origin_packages==='.yellow.swap
  end

  desc 'Populate new destination packages table'
  task populate_destination_package: :environment do
    puts '===Iniciando Migración de Destinos==='.green.swap
    sql_destination_packages = "
    INSERT INTO destination_packages (commune_id, package_id, full_name, phone,
                                      email, number, street, zip_code,
                                      complement, created_at, updated_at)
    SELECT
    addresses.commune_id as commune_id,
    addresses.package_id as package_id,
    packages.full_name as full_name,
    packages.cellphone as phone,
    packages.email as email,
    addresses.number as number,
    addresses.street as street,
    addresses.zip_code as zip_code,
    addresses.complement as complement,
    NOW()::timestamp as created_at,
    NOW()::timestamp as updated_at
    FROM
    packages,
    addresses
    where
    addresses.package_id = packages.id
    ORDER BY packages.id ASC"
    ActiveRecord::Base.connection.execute(sql_destination_packages)
    puts '===Finalizo destination_packages==='.yellow.swap
  end

  desc 'Populate new returns packages table'
  task populate_return_package: :environment do
    puts '=== Iniciando Migración de Retornos ==='.green.swap
    returned_packages = Package.where(status: 'returned')
    returned_packages.each do |package|
      begin
        address_book = package.company.address_books.select { |address| address.addressable_type == 'Return' && address.default }.first
        next unless address_book.present?

        return_package_attributes = {
          commune_id: address_book.address.commune_id,
          package_id: package.id,
          full_name: address_book.full_name,
          phone: address_book.phone,
          email: address_book.email,
          number: address_book.address.number,
          street: address_book.address.street,
          zip_code: address_book.address.zip_code,
          complement: address_book.address.complement,
          return_id: address_book.addressable_id
        }
        ReturnPackage.create!(return_package_attributes)
      rescue StandardError => e
        puts e.message.red.swap
      end
    end
  end
end
