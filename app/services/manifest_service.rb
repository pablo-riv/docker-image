require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/html_outputter'
class ManifestService
  attr_accessor :attributes, :errors
  def initialize(attributes)
    @attributes = attributes
    @errors = []
  end

  def generate_pdf
    pickup = find_pickup
    return if pickup.blank?

    dissociate_packages(pickup)
    data = manifest_data(pickup)
    pdf = generate_manifest_pdf(output_render(data))
    uploaded_pdf = upload_pdf(data, pdf)
    updated_pickup = find_pickup
    return if updated_pickup.blank?

    manifest = Manifest.find_or_create_by(pickup_id: pickup.id)
    manifest.update_attributes(url: uploaded_pdf.public_url)
  end

  private

  def find_pickup
    Pickup.find_by(id: pickup_id, manifest_uuid: manifest_uuid)
  end

  def manifest_data(pickup)
    pickup_shipments = pickup.packages_valid_for_manifest
    company = pickup.company
    {
      id: pickup.id,
      address: { place: pickup.address['place'] },
      provider: @attributes[:provider] || 'shipit',
      shipments: shipments_data_manifest(pickup_shipments),
      person: company.current_account.person.full_name,
      manifest_uuid: pickup.manifest_uuid,
      company: {
        id: company.id,
        name: company.name,
        run: company.run,
        business_turn: company.business_turn
      }
    }
  end

  def output_render(manifest_data)
    view = ActionView::Base.new(Rails.configuration.paths['app/views'])
    view.extend(ApplicationHelper)
    view.extend(Rails.application.routes.url_helpers)
    view.render(template: 'manifest/index',
                pdf: 'Manifiesto',
                locals: { date: Date.current,
                          shipments: manifest_data[:shipments],
                          company: manifest_data[:company],
                          total_items: manifest_data[:shipments].sum { |s| s[:items_count] },
                          address: manifest_data[:address],
                          courier: manifest_data[:provider],
                          person: manifest_data[:person] })
  end

  def generate_manifest_pdf(output)
    WickedPdf.new.pdf_from_string(output,
                                  page_height: '12in',
                                  page_width: '10in',
                                  margin: { top: '30px',
                                            bottom: '30px',
                                            left: '30px',
                                            right: '30px' })
  end

  def upload_pdf(pickup_data, pdf_file)
    creation_time = Time.current
    file_name = "#{creation_time.strftime('%Y-%m-%d %H:%M:%S')} - Manifiesto.pdf"
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket('shipit-manifests')
    uploaded_pdf = bucket.object("shipit/#{creation_time.strftime('%Y/%m/%d')}/#{pickup_data[:company][:id]}/#{file_name}")
    uploaded_pdf.put(body: pdf_file, content_type: 'application/pdf', acl: 'public-read')
    uploaded_pdf
  end

  def pickup_id
    @attributes[:id] || @attributes[:pickup_id]
  end

  def manifest_uuid
    @attributes[:manifest_uuid]
  end

  def shipments_data_manifest(pickup_shipments)
    raise 'Retiro sin envíos' unless pickup_shipments.present?

    pickup_shipments.map do |shipment|
      code = shipment_code(shipment)
      {
        id: shipment.id,
        reference: shipment.reference,
        tracking_number: shipment.tracking_number,
        code: code,
        barcode_number: shipment_barcode(code),
        items_count: shipment.items_count.try(:to_i) || 1,
        full_name: shipment.full_name,
        commune: shipment.address&.commune&.name
      }
    end
  rescue StandardError => e
    error_message = "ManifestService#shipments_data_manifest - ERROR: #{e.message}\nBUGTRACE: #{e.backtrace}"
    Sneakers.logger.info(error_message.red)
    Rails.logger.info(error_message.red)
  end

  def shipment_barcode(code)
    barcode = Barby::Code128.new(code)
    Barby::HtmlOutputter.new(barcode).to_html.html_safe
  end

  def shipment_code(shipment)
    return shipment.id if @attributes[:provider] == 'shipit'

    shipment.tracking_number.presence || shipment.id
  end

  def dissociate_packages(pickup)
    packages_ids = pickup.packages_with_invalid_courier.pluck(:id)
    return [] if packages_ids.blank?

    PackagesPickup.where(pickup_id: pickup.id, package_id: packages_ids)
                  .each(&:destroy)
  end
end
