class WebhookNotification < ApplicationRecord
  def self.by_instance(instance)
    return [] if instance.blank?
    where(model_id: instance.id, model_sent: instance.class.name)
  end
end
