class Invoice < ApplicationRecord
  # RELATIONS
  belongs_to :company

  # CALLBACKS
  after_create :set_track
  before_update :set_track

  # TYPES
  enum state: { created: 0, expired_soon: 1, expired: 2, to_cancel: 3, paid: 4, no_emited: 5 }

  # LOGS
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  # CLASS METHODS

  def self.by_period(emit_date: Date.current)
    where(emit_date: emit_date)
  end

  def self.by_company(company_id)
    where(company_id: company_id)
  end

  def completed?
    state == 'paid' && files['pdf'].present?
  end

  private

  def set_track
    return true if self.state_tracker[state].present?

    self.state_tracker[state] = DateTime.current.strftime('%Y-%m-%d %H:%M:%S')
    update_columns(state_tracker: self.state_tracker)
  end
end
