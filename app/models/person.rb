class Person < ApplicationRecord
  # RELATIONS
  has_one :account

  has_attached_file :profile_image, styles: { large: '1920x1080>', medium: '1280x720>', thumb: '480x340>' }, default_url: ':style/missing.jpeg'
  validates_attachment_content_type :profile_image, content_type: /\Aimage\/.*\Z/
  validates_presence_of :first_name, :last_name
  accepts_nested_attributes_for :account

  def self.allowed_attributes
    [:first_name, :last_name, :birthday, :gender, :profile_image]
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
