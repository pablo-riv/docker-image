class PickAndPack < ApplicationRecord
  # ACT AS
  acts_as_paranoid

  # CALLBACKS
  after_create :generate_relation

  # RELATIONS
  belongs_to :branch_office
  belongs_to :service
  belongs_to :origin
  has_one :cutting_hour, as: :cutting

  # DELEGATIONS
  delegate :acting_as, to: :cutting_hour, prefix: true
  delegate :specific, to: :cutting_hour, prefix: true

  # TYPES
  enum state: { active: 0, inactive: 1 }, _prefix: :state
  enum frequency: { ondemand: 0, recurrent: 1, unique: 2 }, _prefix: :frequency
  enum provider: { shipit: 0, chilexpress: 1, starken: 2, muvsmart: 3, motopartner: 4, chileparcels: 5, bluexpress: 6, shippify: 7 }, _prefix: :provider
  enum manifest: { automatic: 0, manual: 1 }, _prefix: :manifest
  enum seller: { all: 0 }, _prefix: :seller
  enum labels: { all: 0 }, _prefix: :labels

  # SCOPES
  default_scope { where.not(state: :inactive) }

  # CLASS METHODS
  def self.allowed_attributes
    %i[id origin_id provider frequency seller labels manifest]
  end

  private

  def generate_relation
    create_cutting_hour
  end  
end
