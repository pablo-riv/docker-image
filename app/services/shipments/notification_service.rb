module Shipments
  class NotificationService
    attr_accessor :object, :errors

    def initialize(object)
      @object = object
      @errors = []
    end

    def dispatch
      select_availables_to_get_price
      returned? ? returned_email : pickup_email
      fulfill_out_shipment
      enqueue_webhook
      publish_to_pickup
    end

    private

    def pickup_email
      return if company.fulfillment? || test_shipments?
      return unless notification

      OrderMailer.warn_about_hero(shipments, account, branch_office).deliver
    end

    def shipments
      @object[:shipments]
    end

    def account
      @object[:account]
    end

    def company
      @object[:company]
    end

    def branch_office
      @object[:branch_office]
    end

    def notification
      @object[:notification]
    end

    def test_shipments?
      shipments.any?(&:test?)
    end

    def returned?
      shipments.any?(&:is_returned)
    end

    def available_to_pickup
      shipments.reject(&:available_to_pickup?)
    end

    def returned_email
      ReturnedMailer.returned(shipments, account).deliver
    end

    def select_availables_to_get_price
      shipments.select(&:available_to_get_price?).each(&:set_price)
    end

    def select_availables_to_get_tracking
      shipments.map(&:reload).select(&:available_to_get_tracking?).each(&:set_tracking)
    end

    def fulfill_out_shipment
      FulfillmentPackageJob.perform_later(shipments, company) if company.fulfillment?
    end

    def enqueue_webhook
      WebhookJob.perform_later(shipments) if company.webhook_pp_available.present?
    end

    def publish_to_pickup
      Publisher.publish('mass', Package.generate_template_for(3, available_to_pickup, account)) if company.fulfillment? && !test_shipments?
      PickupService.new(branch_office: branch_office, shipments: shipments).add_shipments_to_pickup
    end
  end
end
