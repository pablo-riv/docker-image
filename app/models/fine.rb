class Fine < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  belongs_to :branch_office
  has_one :company, through: :branch_office

  default_scope { where('archive = false') }
  scope :pickup_failed, -> { where(charge_type: 0) }
  scope :parking, -> { where(charge_type: 1) }
  scope :discounts, -> { where(charge_type: 2) }
  scope :refunds, -> { where(charge_type: 2) }
  scope :not_discounts, -> { where.not(charge_type: 2) }
  scope :commercial_discounts, -> { where(charge_type: 3) }

  scope :by_date, ->(year = Date.current.year, month) { where('EXTRACT(YEAR from fines.date) = ? AND EXTRACT(MONTH from fines.date) = ?', year, month) }

  def self.by_periods(periods)
    where(date: periods)
  end
end
