class BsaleWebhook < ApplicationRecord
  belongs_to :company
  has_many :webhook_logs
end
