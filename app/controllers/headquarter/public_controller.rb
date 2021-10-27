module Headquarter
  class PublicController < Headquarter::HeadquarterController
    def dashboard
      @report = {
        total_saved_time: current_account.total_saved_time,
        most_packing_used: current_account.most_packing_used,
        best_day_of_week: current_account.best_day_of_week,
        most_region_package: nil,
        prices_by_package: current_account.prices_by_package.order(id: :desc).limit(10)
      }
      @states = Package.states(current_account)
    end

    def instructions
    end
  end
end
