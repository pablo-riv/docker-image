class Charge < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }
  belongs_to :company

  enum service: { opit: 1, fullit: 2, pickandpack: 3, fullfilment: 4, premium: 5 }

  scope :by_date, ->(year = Date.current.year, month) { where('EXTRACT(YEAR from charges.date)= ? AND EXTRACT(MONTH from charges.date)= ?', year, month) }
  scope :by_year, ->(year = Date.current.year) { where('EXTRACT(YEAR from charges.date)= ?', year) }
  scope :by_day, ->(year = Date.current.year, month, day) { where('EXTRACT(YEAR from charges.date)= ? AND EXTRACT(MONTH from charges.date)= ? AND EXTRACT(DAY from charges.date)= ?', year, month, day) }

  def self.ff_summary_by_month(all_company_charges, company)
    charges_by_month = {}
    charges_by_date = all_company_charges.group_by{ |charge| charge.date.strftime('%Y/%m') }

    charges_by_date.each do |date, charges|
      data = Package.sum_fulfillment_charges(ids: company.branch_offices.ids,
                                             from: date.split('/')[0],
                                             to: date.split('/')[1],
                                             type: 'month')

      charges.each do |charge|
        total_amounts = charge.total_amounts
        if charges_by_month[date].present?
          charges_by_month[date][:total] += (total_amounts[:total] || 0)
          charges_by_month[date][:in] += (total_amounts[:in] || 0)
          charges_by_month[date][:stock] += (total_amounts[:stock] || 0)
          charges_by_month[date][:out] += (total_amounts[:out] || 0)
          charges_by_month[date][:others] += (total_amounts[:others] || 0)
        else
          charges_by_month[date] = total_amounts
        end
        charges_by_month[date][:recurrent_charge] = company.charges.opit.by_date(date.split('/')[0], date.split('/')[1]).where("charges.details ->> 'type' = 'recurrent_charge'").sum("CAST(charges.details ->> 'amount' AS INTEGER)")
        charges_by_month[date][:premium] = company.charges.premium.by_date(date.split('/')[0], date.split('/')[1]).sum("CAST(charges.details ->> 'amount' AS INTEGER)")
        charges_by_month[date][:shipments] = data[:shipments]
        charges_by_month[date][:material_extra] = data[:material_extra]
        charges_by_month[date][:total_is_payable] = data[:total_is_payable]
      end
    end
    charges_by_month
  end

  def total_amount_of(charge_category)
    details[charge_category].map { |charge| charge['amount'] }.sum
  end

  def total_amounts
    data = Package.sum_fulfillment_charges(ids: company.branch_offices.ids,
                                           from: date.at_beginning_of_day,
                                           to: date.at_end_of_day,
                                           type: 'day')
    recurrent_charge_day = company.charges.opit.by_date(date.year, date.month).where("charges.details ->> 'type' = 'recurrent_charge'").sum("CAST(charges.details ->> 'amount' AS INTEGER)") / date.end_of_month.day
    premium_day = company.charges.premium.by_date(date.year, date.month).sum("CAST(charges.details ->> 'amount' AS INTEGER)") / date.end_of_month.day
    amounts = {
      in: total_amount_of('in'),
      stock: total_amount_of('stock'),
      out: total_amount_of('out'),
      others: total_amount_of('others'),
      shipments: data[:shipments],
      recurrent_charge: recurrent_charge_day,
      premium: premium_day.round,
      total_is_payable: data[:total_is_payable],
      material_extra: data[:material_extra]
    }
    amounts[:total] = amounts.values.sum
    amounts
  end

  def self.toal_monthly_shipments(company, month)
    company.packages.by_date(month).no_paid_by_shipit
  end

  def self.base_by_periods(periods)
    where(date: periods).where("charges.details ->> 'type' = 'base_charge_pp'")
  end
end
