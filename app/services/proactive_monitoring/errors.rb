module ProactiveMonitoring
  module Errors
    class ProactiveMonitoringError < ::StandardError; end

    class PackageNotFound < ProactiveMonitoringError
      def message
        I18n.t('proactive_monitoring.error.package_not_found')
      end
    end

    class UnpermittedCourier < ProactiveMonitoringError
      def message
        I18n.t('proactive_monitoring.error.unpermitted_courier')
      end
    end

    class ShippingManagementNotFound < ProactiveMonitoringError
      def message
        I18n.t('proactive_monitoring.error.shipping_management_not_found')
      end
    end

    class KeepShippingState < ProactiveMonitoringError
      def message
        I18n.t('proactive_monitoring.error.keep_shipping_state')
      end
    end

    class SubStatusNotMapped < ProactiveMonitoringError
      def message
        I18n.t('proactive_monitoring.error.sub_status_not_mapped')
      end
    end

    class PackageSubStatusNotFound < ProactiveMonitoringError
      def message
        I18n.t('proactive_monitoring.error.package_sub_status_not_found')
      end
    end
  end
end
