class Packing < ApplicationRecord
  # CALLBACKS
  after_save :check_default
  after_save :calculate_volumetric_weight
  # RELATIONS
  belongs_to :company
  has_many :package_packings

  # VALIDATIONS
  validates_presence_of :name, :weight, :sizes
  validates :company, presence: true

  # SCOPES
  default_scope { where(archive: false) }

  store :sizes, accessors: %i(width height length volumetric_weight)

  def self.allowed_attributes
    [:name, :company_id, :weight, :default, :width, :height, :length, :volumetric_weight, sizes: [:width, :height, :length, :volumetric_weight]]
  end

  def short_measures
    "#{sizes['height']}x#{sizes['length']}x#{sizes['width']}"
  end

  private

  def check_default
    return unless self.default

    self.company.packings.where.not(id: self.id).update_all(default: false)
  end

  def calculate_volumetric_weight
    volumetric_weight = [(sizes['height'].to_f * sizes['length'].to_f * sizes['width'].to_f / 4000), weight].max
    update_columns(sizes: sizes.merge(volumetric_weight: volumetric_weight))
  end
end
