class Whatsapp < ApplicationRecord
  # RELATIONS
  belongs_to :package
  before_create :sent_status?
  enum state: { in_preparation: 0, created: 13, in_route: 1, delivered: 2, failed: 3, by_retired: 4 }, _suffix: true
  accepts_nested_attributes_for :package

  def self.delivered(state)
    find_by(state: state, sent: true)
  end

  def self.not_delivered(state)
    find_by(state: state, sent: false)
  end

  def self.between_dates(from, to)
    where(created_at: (from.to_date.at_beginning_of_day..to.to_date.at_end_of_day))
  end

  private

  def sent_status?
    sent = package.whatsapps.find_by(package_id: package_id, state: state)
    sent.present? ? false : true
  end
end
