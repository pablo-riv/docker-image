class Incidence < ApplicationRecord
  include SiteNotificable

  # RELATIONS
  has_and_belongs_to_many :supports, join_table: 'supports_incidences'
  belongs_to :package
  belongs_to :actable, polymorphic: true
  has_many :incidence_messages
  has_one :site_notification, as: :actable
  delegate :company, to: :package

  # TYPES
  enum status: { pending: 0, waiting: 1, completed: 2, cancelled: 3 }
end
