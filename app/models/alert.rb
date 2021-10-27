class Alert < ApplicationRecord
  acts_as_paranoid

  # RELATIONS
  belongs_to :package
  has_many :alert_traces, dependent: :destroy
  before_create :validate_creation

  # TYPES
  enum state: { in_preparation: 0, created: 13, in_route: 1, delivered: 2, failed: 3, by_retired: 4 }, _suffix: true
  accepts_nested_attributes_for :package

  # CLASS METHODS
  def self.delivered(state)
    find_by(state: state, email_sent: true)
  end

  def self.not_delivered(state)
    find_by(state: state, email_sent: false)
  end

  def self.between_dates(from, to)
    where(created_at: (from.to_date.at_beginning_of_day..to.to_date.at_end_of_day))
  end

  def self.pendings
    where(sent_at: nil, status: %w[created processing email_created error])
      .left_joins(:alert_traces)
      .group('alerts.id')
      .having('count(alerts.id) < ?', 3)
  end

  # METHODS
  def attempts
    alert_traces.count
  end

  private

  def validate_creation
    error_msg = "Alert exist for package_id #{package_id} state #{state}"
    raise error_msg if package.alerts.exists?(package_id: package_id, state: state)
  end
end
