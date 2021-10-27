module Zendesk
  module Metrics
    def format_metrics(raw_metrics)
      @ticket_metric = raw_metrics
      build_metrics
    end

    private

    def build_metrics
      { solved_at: solved_at,
        replies: replies,
        reopens: reopens,
        reply_time_in_minutes_calendar: reply_time_in_minutes_calendar,
        reply_time_in_minutes_business: reply_time_in_minutes_business,
        first_resolution_time_in_minutes_calendar: first_resolution_time_in_minutes_calendar,
        first_resolution_time_in_minutes_business: first_resolution_time_in_minutes_business,
        agent_wait_time_in_minutes_calendar: agent_wait_time_in_minutes_calendar,
        agent_wait_time_in_minutes_business: agent_wait_time_in_minutes_business,
        requester_wait_time_in_minutes_calendar: requester_wait_time_in_minutes_calendar,
        requester_wait_time_in_minutes_business: requester_wait_time_in_minutes_business,
        on_hold_time_in_minutes_calendar: on_hold_time_in_minutes_calendar,
        on_hold_time_in_minutes_business: on_hold_time_in_minutes_business }
    end

    def solved_at
      @ticket_metric[:solved_at]
    end

    def replies
      @ticket_metric[:replies]
    end

    def reopens
      @ticket_metric[:reopens]
    end

    def reply_time_in_minutes_calendar
      @ticket_metric[:reply_time_in_minutes][:calendar]
    end

    def reply_time_in_minutes_business
      @ticket_metric[:reply_time_in_minutes][:business]
    end

    def first_resolution_time_in_minutes_calendar
      @ticket_metric[:first_resolution_time_in_minutes][:calendar]
    end

    def first_resolution_time_in_minutes_business
      @ticket_metric[:first_resolution_time_in_minutes][:business]
    end

    def agent_wait_time_in_minutes_calendar
      @ticket_metric[:agent_wait_time_in_minutes][:calendar]
    end

    def agent_wait_time_in_minutes_business
      @ticket_metric[:agent_wait_time_in_minutes][:business]
    end

    def requester_wait_time_in_minutes_calendar
      @ticket_metric[:requester_wait_time_in_minutes][:calendar]
    end

    def requester_wait_time_in_minutes_business
      @ticket_metric[:requester_wait_time_in_minutes][:business]
    end

    def on_hold_time_in_minutes_calendar
      @ticket_metric[:on_hold_time_in_minutes][:calendar]
    end

    def on_hold_time_in_minutes_business
      @ticket_metric[:on_hold_time_in_minutes][:business]
    end
  end
end
