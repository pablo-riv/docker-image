class Location < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  ## RELATIONS
  belongs_to :hero
  belongs_to :branch_office
  belongs_to :area
  def self.by_branch_office(id)
    find_by(branch_office_id: id)
  end
end
