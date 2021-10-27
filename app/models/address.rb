class Address < ApplicationRecord
  # CALLBACKS
  after_commit :send_to_elastic

  # RELATIONS
  belongs_to :commune
  belongs_to :package
  has_one :wrong_address
  has_one :entity
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  # VALIDATIONS
  validates_presence_of :commune_id, :street, :number, on: :update, if: :validate_address?
  delegate :name, to: :commune, allow_nil: true, prefix: 'commune'
  delegate :id, to: :commune, allow_nil: true, prefix: 'commune'
  delegate :region_name, to: :commune, allow_nil: true, prefix: 'commune'

  # CLASS METHODS
  def self.allowed_attributes
    [:commune_id, :complement, :number, :street, coords: {}]
  end

  # INSTANCE METHODS
  def full
    "#{street} #{number}, #{commune.name.titleize}, Región #{commune.region.name.titleize}"
  rescue NoMethodError => e
    puts e.message.to_s.red
  end

  def serialize_data!
    serializable_hash(include: { commune: { include: { region: { include: [:country] } } } },
                      methods: [:full])
  end

  def serialize_shipment!
    serializable_hash(methods: [:full, :commune_name])
  end

  def validate_address?
    return true if package.present?
    return true if entity.blank?
    return true if entity.actable_type.downcase == 'company' && entity.specific.platform_version == 2
    return true if entity.actable_type.downcase == 'branchoffice' && entity.specific.company.platform_version == 2

    false
  rescue => e
    true
  end
end
