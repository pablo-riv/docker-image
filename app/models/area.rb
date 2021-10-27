class Area < ApplicationRecord
  ## RELATIONS
  has_many :locations
  has_many :branch_offices, through: :locations
  has_many :heros, through: :locations
  has_one :cutting_hour, as: :cutting
  belongs_to :distribution_center

  # TYPES
  store :cutting_hours, accessors: %i(pp ff ll)

  # INSTANCE METHODS
  def default_hero
    hero = heros.first
    hero.blank? ? 'Área no cuenta con héroe asignado' : "#{hero.initials} | #{hero.full_name}"
  end

  def formated_coords
    return [] if coords.blank?

    coords.map { |coord| { 'latitude' => coord['latitude'].try(:to_f), 'longitude' => coord['longitude'].try(:to_f) } }
  end
end
