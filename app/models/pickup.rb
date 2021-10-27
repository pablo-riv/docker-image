class Pickup < ApplicationRecord
  # CALLBACKS
  before_create :build_pickup_uuid

  # RELATIONS
  has_and_belongs_to_many :packages, join_table: :packages_pickups, foreign_key: :pickup_id
  has_one :manifest
  belongs_to :branch_office
  has_one :company, through: :branch_office

  # TYPES
  enum provider: { shipit: 0, chilexpress: 1, starken: 2, muvsmart: 3, motopartner: 4, chileparcels: 5, bluexpress: 6, shippify: 7 }
  enum status: { pending: 0, shipped: 1, shipped_with_issues: 2, failed: 3, cancelled: 4, no_retired: 5 }
  enum type_of_pickup: { daily: 0, scheduled: 1 }

  default_scope { where(archive: false) }

  def self.allowed_attributes
    %i[id provider schedule status]
  end

  def self.daily_pickups
    where("pickups.schedule ->> 'date' = ? AND status IN (0, 5)", Date.current.strftime('%Y-%m-%d'))
  end

  def sdd_couriers
    Courier.ssd_couriers_names
  end

  def packages_valid_for_manifest
    Package.valid_for_manifest(id)
  end

  def packages_with_invalid_courier
    packages.where(courier_for_client: sdd_couriers).order(:id)
  end

  def generate_manifest
    return 'Retiro sin sucursal asignada' unless branch_office.present?

    ManifestService.new(provider: provider.presence || 'shipit',
                        pickup_id: id,
                        manifest_uuid: manifest_uuid).generate_pdf
  end

  def dispatch_manifest
    SuiteNotifications::Publish.new(channel: 'manifest',
                                    company: branch_office.company,
                                    dispatch: { id: id, manifest: manifest&.url }).publish
  end

  def build_pickup_uuid
    self.pickup_uuid = UuidGeneratorService.pickup_uuid(self)
  end

  def update_uuids
    pickup_params = { manifest_uuid: UuidGeneratorService.manifest_uuid(self) }
    pickup_params[:pickup_uuid] = UuidGeneratorService.pickup_uuid(self) if pickup_uuid.blank?
    update_columns(pickup_params)
  end
end
