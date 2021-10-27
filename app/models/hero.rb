class Hero < ApplicationRecord
  ## CALLBACKS
  after_commit :send_to_elastic

  ## RELATIONS
  has_many :locations
  has_many :areas, through: :locations
  ## ACT AS USER
  acts_as :user

  has_attached_file :identity_image, styles: { large: '1920x1080>', medium: '1280x720>', small: '480x340>', thumb: '50x50>' }, default_url: ':style/missing.jpeg'
  validates_attachment_content_type :identity_image, content_type: /\Aimage\/.*\Z/

  # INSTANCE METHODS
  def serialize_data!
    serializable_hash(include: :person, methods: [:hero_image])
  end

  def hero_image
    identity_image.url(:medium).include?('missing') ? 'https://s3-us-west-2.amazonaws.com/shipit-platform/ala.png' : identity_image.url(:medium)
  end
end
