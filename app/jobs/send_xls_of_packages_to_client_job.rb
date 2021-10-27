class SendXlsOfPackagesToClientJob < ApplicationJob
  queue_as :default

  def perform(packages, type, account)
    book = Spreadsheet::Workbook.new
    book.create_worksheet(name: "Envíos #{type}")
    book.worksheet(0).insert_row(0, ['ID Shipit', I18n.t('activerecord.attributes.package.reference'), I18n.t('activerecord.attributes.package.created_at'), I18n.t('activerecord.attributes.package.full_name'), I18n.t('activerecord.attributes.package.shipping_price'), I18n.t('activerecord.attributes.package.material_extra'), I18n.t('activerecord.attributes.package.total_is_payable'), I18n.t('activerecord.attributes.package.total_price')]) #headers
    packages.each_with_index do |package, index|
      book.worksheet(0).insert_row((index + 1), [package.id,
                                                 package.reference,
                                                 package.created_at.strftime('%d/%m/%Y %H:%M'),
                                                 package.full_name,
                                                 package.shipping_price,
                                                 package.material_extra,
                                                 package.total_is_payable,
                                                 [package.shipping_price || 0, package.material_extra || 0, package.total_is_payable || 0].sum]) #rows
    end
    book.write("public/Envíos #{account.entity.name} - #{type}.xls")
    "public/Envíos #{account.entity.name} - #{type}.xls"
  end
end
