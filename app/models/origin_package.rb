class OriginPackage < ApplicationRecord
  belongs_to :commune
  belongs_to :package
  belongs_to :origin

  delegate :name, to: :commune, allow_nil: true, prefix: 'commune'

  validates_presence_of :commune_id, :package_id, :origin_id

  def full_address
    "#{street} #{number}, #{commune_name}, #{commune.country_name}"&.titleize
  end
end
