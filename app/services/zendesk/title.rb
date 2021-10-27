module Zendesk
  class Title
    def initialize(reference_number = '')
      @reference_number = reference_number
    end

    def lost_parcel
      I18n.t('zendesk.title.lost_parcel',
             reference_number: @reference_number)
    end

    def wrong_address
      I18n.t('zendesk.title.wrong_address',
             reference_number: @reference_number)
    end

    def change_address_with_client
      I18n.t('zendesk.title.change_address_with_client',
             reference_number: @reference_number)
    end

    def change_address_with_courier
      I18n.t('zendesk.title.change_address_with_courier',
             reference_number: @reference_number)
    end
  end
end
