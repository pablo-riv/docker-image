class SendXlsOfFulfillmentChargesToClientJob < ApplicationJob
  queue_as :default

  def perform(charges, type, account)
    book = Spreadsheet::Workbook.new
    book.create_worksheet(name: "Cobros Fulfillment #{type}")
    book.worksheet(0).insert_row(0, [I18n.t('activerecord.attributes.charges.fulfillment.date'), I18n.t('activerecord.attributes.charges.fulfillment.in'),
                                    I18n.t('activerecord.attributes.charges.fulfillment.stock'), I18n.t('activerecord.attributes.charges.fulfillment.out'),
                                    I18n.t('activerecord.attributes.charges.fulfillment.shipping_cost'), I18n.t('activerecord.attributes.charges.fulfillment.others'),
                                    I18n.t('activerecord.attributes.charges.fulfillment.premium'), I18n.t('activerecord.attributes.charges.fulfillment.recurrent_charge'),
                                    I18n.t('activerecord.attributes.charges.fulfillment.total')]) #headers
    charges.each_with_index do |charge, index|
      if type.downcase.include?('anual')
        book.worksheet(0).insert_row((index + 1), [I18n.l(Date.parse(charge[0]), format: '%B %Y'),
                                                   charge[1][:in].try(:to_i),
                                                   charge[1][:stock].try(:to_i),
                                                   charge[1][:out].try(:to_i),
                                                   ChargesController.helpers.sum_shipments(charge[1]).try(:to_i),
                                                   charge[1][:others].try(:to_i),
                                                   charge[1][:premium].try(:to_i),
                                                   charge[1][:recurrent_charge].try(:to_i),
                                                   ChargesController.helpers.total_warehouse_shipments(charge[1]).try(:to_i)]) #rows
      else
        total_amounts = charge.total_amounts
        book.worksheet(0).insert_row((index + 1), [I18n.l(charge.date, format: '%d/%m/%Y'),
                                                   total_amounts[:in].try(:to_i),
                                                   total_amounts[:stock].try(:to_i),
                                                   total_amounts[:out].try(:to_i),
                                                   ChargesController.helpers.sum_shipments(total_amounts).try(:to_i),
                                                   total_amounts[:others].try(:to_i),
                                                   total_amounts[:premium].try(:to_i),
                                                   total_amounts[:recurrent_charge].try(:to_i),
                                                   ChargesController.helpers.total_warehouse_shipments(total_amounts).try(:to_i)]) #rows
      end
    end
    book.write("public/Cobros Fulfillment #{account.entity.name} - #{type}.xls")
    "public/Cobros Fulfillment #{account.entity.name} - #{type}.xls"
  end
end
