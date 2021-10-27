class CourierAlias < ApplicationRecord
  belongs_to :courier

  validates_uniqueness_of :name

  def self.by_name(name)
    find_by('LOWER(name) like ?', "%#{name.try(:downcase)}%")
  end
end
