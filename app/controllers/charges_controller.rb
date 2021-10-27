class ChargesController < ApplicationController
  include ChargesHelper

  before_action :set_company, only: %i[index pickandpack pickandpack_by_month pickandpack_by_month_csv pickandpack_extras_by_month fines parking discounts fullfilment fullfilment_by_month fullfilment_by_month_details fulfillment_xls]
  before_action :set_date, only: %i[fullfilment fullfilment_by_month fullfilment_by_month_details pickandpack_by_month pickandpack_by_month_csv pickandpack_extras_by_month]
  before_action :set_packages, only: %i[fulfillment_month_packages fulfillment_day_packages fulfillment_packages_xls]
  before_action :set_charges, only: %i[fulfillment_xls]
  # before_action :return_to_root

  def index; end

  def fullfilment
    @charges = @company.charges.fullfilment.by_year(@date.year)
    @charges_by_month = Charge.ff_summary_by_month(@charges, @company)
    @charges_by_month = @charges_by_month.sort.reverse
  end

  def fullfilment_by_month
    @charges = @company.charges.fullfilment.by_date(@date.year, @date.month).order(date: :desc)
    @totals = {
      in: 0,
      stock: 0,
      out: 0,
      others: 0,
      shipments: 0,
      resume: 0,
      recurrent_charge: 0,
      premium: 0,
      total_premium: @company.charges.premium.by_date(@date.year, @date.month).sum("CAST(charges.details ->> 'amount' AS INTEGER)"),
      recurrent_total_charge: @company.charges.opit.by_date(@date.year, @date.month).where("charges.details ->> 'type' = 'recurrent_charge'").sum("CAST(charges.details ->> 'amount' AS INTEGER)")
    }
    @charges.each_with_index do |charge, i|
      total_amounts = charge.total_amounts
      @totals[:in] += total_amounts[:in].try(:round)
      @totals[:stock] += total_amounts[:stock].try(:round)
      @totals[:out] += total_amounts[:out].try(:round)
      @totals[:others] += total_amounts[:others].try(:round)
      @totals[:premium] += total_amounts[:premium].try(:round)
      @totals[:recurrent_charge] += total_amounts[:recurrent_charge].try(:round)
      @totals[:shipments] += sum_shipments(total_amounts)
      @totals[:resume] += total_warehouse_shipments(total_amounts)
    end
  end

  def fulfillment_xls
    raise 'Sin cobros disponibles' unless @charges.present?
    file = SendXlsOfFulfillmentChargesToClientJob.perform_now(@charges, @type, current_account)
    send_data File.read(file), filename: file.split('/').second
  end

  def fullfilment_by_month_details
    @charges = @company.charges.fullfilment.by_date(@date.year, @date.month).order(date: :desc)
  end

  def fulfillment_month_packages
    @packages = @packages.page(params[:page]).per(50)
  end

  def fulfillment_day_packages
    @packages = @packages.page(params[:page]).per(50)
  end

  def fulfillment_packages_xls
    raise 'Sin envíos disponibles' unless @packages.present?
    file = SendXlsOfPackagesToClientJob.perform_now(@packages, @type, current_account)
    send_data File.read(file), filename: file.split('/').second
  end

  def pickandpack
    @charges_by_month = {}
    @date = params[:year].to_i.zero? ? Date.current : Date.new(params[:year].to_i)
    @company.packages.by_year(@date.year).no_paid_by_shipit.not_sandbox.not_test.each do |package|
      date = package.billing_date.try(:strftime, '%Y/%m')
      next unless date.present?

      package_shipping_price = 0
      extras = 0
      total_is_payable = 0

      unless package.is_paid_shipit # exclude packages paid_by_shipit
        if package.is_returned
          package_shipping_price = 0 # exclude from shipping
          extras += (package.total_price unless package.is_payable) || 0 # include total as extras
          total_is_payable += package.total_is_payable || 0
        else
          package_shipping_price = package.shipping_price || 0
          total_is_payable += package.total_is_payable || 0
          extras += package.material_extra || 0
        end
      end

      if @charges_by_month[date].present?
        @charges_by_month[date][:shipping] += package_shipping_price
        @charges_by_month[date][:extras] += extras
        @charges_by_month[date][:total_is_payable] += total_is_payable
        @charges_by_month[date][:total] += package_shipping_price + extras + total_is_payable
      else
        @charges_by_month[date] = { shipping: package_shipping_price,
                                    extras: extras,
                                    total_is_payable: total_is_payable,
                                    total: package_shipping_price + extras + total_is_payable }
      end
    end
    normalize = -> (value) { value.nil? ? 0 : value.to_f }
    @charges_by_month.each do |month_summary|
      date = Date.parse(month_summary[0])
      base_charge = @company.charges.by_date(date.year, date.month).where("charges.details ->> 'type' = 'base_charge_pp'")
      base = base_charge.blank? ? 0 : base_charge[0].details['amount']
      recurrent_charge = @company.charges.opit.by_date(date.year, date.month).where("charges.details ->> 'type' = 'recurrent_charge'").sum("CAST(charges.details ->> 'amount' AS INTEGER)")
      premium = @company.charges.premium.by_date(date.year, date.month).sum("CAST(charges.details ->> 'amount' AS INTEGER)")
      parking = @company.fines.parking.by_date(date.year, date.month).sum(:amount)
      fines = @company.fines.pickup_failed.by_date(date.year, date.month).sum(:amount)
      discounts = @company.fines.discounts.by_date(date.year, date.month).sum(:amount)
      month_summary[1][:extras] += fines + parking - discounts
      month_summary[1][:total] += [premium, recurrent_charge, base, fines, parking].reduce(0) { |acc, value| acc + normalize.call(value) } - discounts
      month_summary[1][:base] = base
      month_summary[1][:recurrent_charge] = recurrent_charge
      month_summary[1][:premium] = premium
    end
    @charges_by_month = @charges_by_month.sort.reverse
  end

  def pickandpack_by_month
    @packages = @company.packages.by_billing_date(@date.year, @date.month).not_sandbox.not_test.order(created_at: :desc).page(params[:page]).per(20)
    @summary = @company.charges_summary(@date.year, @date.month)
    @extras = @summary[:fines] + @summary[:returns] + @summary[:material_extra] + @summary[:parking] - @summary[:discounts]
    render 'charges/pickandpack/by_month'
  end

  def pickandpack_by_month_csv
    @packages = @company.packages.includes({ branch_office: :company }, :address, :commune).by_billing_date(@date.year, @date.month).not_sandbox.not_test.order(created_at: :desc)
    report = CSV.generate(encoding: 'UTF-8'.encoding) do |csv|
      csv << ['Fecha Creación', 'Fecha Contable', 'Destinatario', 'Calle', 'Número', 'Comuna', 'Código de envío', 'Largo', 'Ancho', 'Alto', 'Peso', 'Bultos',
              'Número de seguimiento', 'Volumen', 'Por Pagar', 'Precio envío', 'Material extra', 'Pagado por Shipit', 'Total por pagar', 'Precio total', 'URL', 'Sucursal']
      @packages.each do |package|
        csv << [l(package.created_at, format: '%d/%m/%Y'), package.billing_date.try(:strftime, '%d/%m/%Y') || '', package.full_name, package.address.try(:street), package.address.try(:number),
                package.address.try(:commune).try(:name), package.reference, package.length, package.width, package.height, package.weight,
                package.items_count, package.tracking_number, package.volume_price, (package.is_payable ? 'SI' : 'NO'), package.shipping_price.try(:to_i),
                package.material_extra.try(:to_i), ('SI' if package.is_paid_shipit), package.total_is_payable.try(:to_i), package.total_price.try(:to_i), package_url(package), package.branch_office.name]
      end
    end

    send_data report, filename: "Envíos #{l(@date, format: '%B %Y')}.csv"
  end

  def pickandpack_extras_by_month
    @summary = @company.charges_summary(@date.year, @date.month)
    @extras = @summary[:fines] + @summary[:returns] + @summary[:material_extra] + @summary[:parking] - @summary[:discounts]
    @packages = @company.packages.by_billing_date(@date.year, @date.month).not_sandbox.not_test.order(created_at: :desc)
    @paid_by_shipit = @packages.paid_by_shipit
    @returned = @packages.no_paid_by_shipit.returned
    @with_material_extra = @packages.no_paid_by_shipit.where.not(material_extra: [nil, 0])
    @pickup_fines = @company.fines.pickup_failed.by_date(@date.year, @date.month).includes(:branch_office).order(created_at: :desc)
    @parking_fines = @company.fines.parking.by_date(@date.year, @date.month).includes(:branch_office).order(created_at: :desc)
    @discounts = @company.fines.discounts.by_date(@date.year, @date.month).includes(:branch_office).order(created_at: :desc)
    render 'charges/pickandpack/extras_by_month'
  end

  def fines
    @pickup_fines = @company.fines.pickup_failed.order(created_at: :desc)
  end

  def parking
    @parking_fines = @company.fines.parking.order(created_at: :desc)
  end

  def discounts
    @discounts = @company.fines.discounts.order(created_at: :desc)
  end

  private

  def set_company
    @company = current_account.entity.specific
  end

  def set_date
    month = params[:month].present? ? params[:month] : '01'
    @date = Date.parse("#{params[:year]}/#{month}")
  rescue ArgumentError
    redirect_to(fullfilment_charges_path)
  end

  def set_packages
    @company = current_account.entity.specific
    @packages = @company.packages
    @packages =
      if params[:day].present?
        @packages.from_billing_day(params[:year].to_i, params[:month].to_i, params[:day].to_i).no_paid_by_shipit.order(created_at: :desc)
      else
        @packages.includes(:address, :commune, branch_office: :company).by_billing_date(params[:year].to_i, params[:month].to_i).no_paid_by_shipit.where.not(total_price: nil).order(created_at: :desc)
      end
    @total_packages = @packages
    @type = params[:day].present? ? 'Diario' : 'Mensual'
  end

  def set_charges
    @charges =
      if params[:month].present?
        @company.charges.fullfilment.by_date(params[:year], params[:month]).order(date: :desc)
      else
        charges_by_month = Charge.ff_summary_by_month(@company.charges.fullfilment.by_year(params[:year]), @company)
        charges_by_month.sort.reverse
      end
    @type = params[:month].present? ? 'Mensual' : 'Anual'
  end

  def return_to_root
    flash[:info] = 'La página que solicitas se encuentra en mantención en este momento.
       Si necesitas resolver alguna duda sobre tus pagos, puedes enviarla al correo soporte@shipit.cl y te responderemos lo antes posible.'
    redirect_to root_path
  end
end
