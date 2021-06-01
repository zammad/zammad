# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Escalation
  class TicketBizBreak
    def initialize(ticket, calendar)
      @ticket       = ticket
      @history_list = ticket.history_get
      @calendar     = calendar
    end

    def biz_breaks
      accumulate_breaks(history_list_in_break.map { |from, to| history_range_to_breaks(from, to) })
    end

    private

    def history_list_states
      @history_list_states ||= @history_list.select { |elem| elem['attribute'] == 'state' }
    end

    def history_list_in_break
      @history_list_in_break ||= begin
        history_list_states
          .tap { |elem| elem.unshift(mock_initial_state) if mock_initial_state }
          .each_cons(2) # group in from/to pairs
          .select { |from, to| range_on_break?(from, to) }
      end
    end

    def ignored_escalation_state_names
      @ignored_escalation_state_names ||= Ticket::State.where(ignore_escalation: true).map(&:name)
    end

    def range_on_break?(from, _to)
      ignored_escalation_state_names.include? from['value_to']
    end

    def history_range_to_breaks(from, to)
      date_from = from['created_at'].in_time_zone(@calendar.timezone)
      date_to   = to['created_at'].in_time_zone(@calendar.timezone)

      (date_from.to_date..date_to.to_date).each_with_object({}) do |elem, memo|
        key   = history_range_break_key(elem, date_from)
        value = history_range_break_value(elem, date_to)

        memo[elem] = { key => value }
      end
    end

    def history_range_break_key(elem, date_from)
      elem == date_from.to_date ? date_from.strftime('%H:%M') : '00:00'
    end

    def history_range_break_value(elem, date_to)
      elem == date_to.to_date ? date_to.strftime('%H:%M') : '24:00'
    end

    def accumulate_breaks(input)
      input.each_with_object({}) do |elem, memo|
        memo.deep_merge! elem
      end
    end

    def mock_initial_state
      @mock_initial_state ||= begin
        first_state = history_list_states.first

        # if history set right on ticket creation, no need for extra step
        if first_state&.dig('created_at') == @ticket.created_at
          nil
        else
          {
            'value_to'   => first_state&.dig('value_from') || @ticket.state.name, # if no history yet, use current state
            'created_at' => @ticket.created_at
          }
        end
      end
    end
  end
end
