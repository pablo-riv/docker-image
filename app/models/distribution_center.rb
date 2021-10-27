class DistributionCenter < ApplicationRecord
  belongs_to :address
  has_one :commune, through: :address
  has_one :cutting_hour, as: :cutting

  accepts_nested_attributes_for :address

  store :cutting_hours, accessors: %i(pp ff ll)

  def self.default
    DistributionCenter.first
  end

  # def cutting_hour(service = 'pp', plus = [])
  #   memo = cutting_hours[service].try(:to_f)
  #   plus.each do |to_sum|
  #     # it prevent error of nil coerced into float
  #     next unless to_sum.try(:to_f).present?

  #     memo += to_sum.try(:to_f)
  #   end
  #   # included at production env
  #   Time.zone.at((memo + 3)*3600).in_time_zone('America/Santiago').strftime('%H:%M') + Time.zone.now.strftime("%z")
  # end
end
