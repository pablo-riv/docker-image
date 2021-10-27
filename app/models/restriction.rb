class Restriction < ApplicationRecord
  KINDS = %w[base_charge cutting_hour available_return_emails]
  store :statements, accessors: %i[amount old_amount packages_count start end active], coder: JSON
  validates_presence_of :kind, message: I18n.t('activerecord.errors.models.restriction.kind.blank')
end
