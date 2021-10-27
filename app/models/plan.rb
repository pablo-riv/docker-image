class Plan < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }
  has_many :companies, through: :subscriptions
  has_many :subscriptions
end
