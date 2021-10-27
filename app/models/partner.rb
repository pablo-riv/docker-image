class Partner < ApplicationRecord
  # RELATIONS
  has_many :companies
  has_many :packages, through: :companies
  has_many :branch_offices, through: :companies
  # CONSTANT
  KIND = [['Agencia de Marketing', 'marketing_agence'], ['Cliente', 'client'], ['Campaña', 'marketing_campaign'], ['Creadores de eCommerce', 'ecommerce_builder'], ['Plataforma eCommerce', 'ecommerce_platform'], ['Oferta Especial', 'special_sale'], ['Otro', 'other']].freeze
  # TYPES
  enum kind: {
    marketing_agence: 0,
    client: 1,
    marketing_campaign: 2,
    ecommerce_builder: 3,
    ecommerce_platform: 4,
    special_sale: 5,
    other: 6
  }
  attr_accessor :profile_image

  # VALIDATIONS
  has_attached_file :logo, styles: { large: '1920x1080>', medium: '1280x720>', small: '480x340>', thumb: '50x50>' }, default_url: ':style/missing.jpeg'
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/

  # SCOPES
  default_scope { where(active: true) }

  # CLASS METHODS
  def self.allowed_attributes
    %i[name code amount logo kind active]
  end
end
