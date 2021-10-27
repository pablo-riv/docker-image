class Indicator < ApplicationRecord
  validates :code, presence: true
  validates :value, presence: true
  scope :uf, -> { where(code: 'UF') }

  default_scope { order(created_at: :asc) }

  def self.last_uf_value
    Indicator.uf.order(created_at: :asc).last.try(:value) || 1
  end

  def self.uf_by_date(date)
    Indicator.uf.where("EXTRACT(year from created_at) = ? AND EXTRACT(month from created_at) = ?", date.year, date.month).last.value
  end

  def self.by_periods(periods)
    where(created_at: periods)
  end
end
