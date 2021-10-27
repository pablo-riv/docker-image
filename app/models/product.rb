class Product < ApplicationRecord
  # RELATIONS
  belongs_to :company

  # VALIDATIONS
  validates_presence_of :name, :weight, :sizes
  validates :company, presence: true

  # TYPES
  has_attached_file :image, styles: { large: '1920x1080>', medium: '1280x720>', small: '480x340>', thumb: '50x50>' }, default_url: '/assets/missing.png'
  validates_attachment :image, content_type: { content_type: ['image/png', 'image/jpeg', 'image/jpg'] }

  before_save :define_volumetric_weight

  # SCOPES
  default_scope { where(archive: false) }

  store :sizes, accessors: %i(width height length volumetric_weight)

  def self.allowed_attributes
    [:name, :company_id, :weight, :description, :sku, :stock, :price, :width, :height, :length, :volumetric_weight, sizes: [:width, :height, :length, :volumetric_weight]]
  end

  def upload_image(data)
    image = Paperclip.io_adapters.for(data)
    image.original_filename = "product_#{name}.png"

    image
  end

  def short_measures
    "#{height}x#{length}x#{width}"
  end

  def define_volumetric_weight
    sizes['volumetric_weight'] = ((height.try(:to_f) || 1) * (length.try(:to_f) || 1) * (width.try(:to_f) || 1)) / 4000
  end
end
