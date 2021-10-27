class CustomerSatisfaction < ApplicationRecord
  # OOP
  include SiteNotificable

  # RELATIONS
  belongs_to :support
  belongs_to :contact
  has_one :site_notification, as: :actable

  # TYPES
  enum response: { good: 0, bad: 1 }, _prefix: :response

  # CALLBACKS
  after_update :syncronize_csat_zendesk

  def syncronize_csat_zendesk
    data = {
      ticket_id: support.ticket_id,
      email: support.company.current_account_email,
      password: support.company.current_zendesk_password,
      response: response,
      comment: comment
    }
    Publisher.publish('customer_satisfaction', data)
  end
end
