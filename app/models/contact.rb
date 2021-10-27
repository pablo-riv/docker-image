class Contact < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }
  belongs_to :company

  # TO ADD A NEW ROLE, INCLUDE IT ON THE LIST.
  ROLES = %W[administrative operative]

  def self.allowed_attributes
    %i[email first_name last_name phone]
  end

  def full_name
    "#{first_name} #{last_name}"
  end

end
