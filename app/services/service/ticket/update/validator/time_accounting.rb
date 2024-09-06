# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator
  class TimeAccounting < Base

    def validate!
      return if !Setting.get('time_accounting')
      return if !TicketPolicy.new(@user, @ticket).agent_update_access?
      return if !time_accounting_condition_matches?

      raise ConditionMatchesError
    end

    class ConditionMatchesError < StandardError
      def initialize
        super(__('The ticket time accounting condition is met.'))
      end
    end

    private

    def time_accounting_condition_matches?
      CoreWorkflow.matches_selector?(
        check:    'selected',
        id:       @ticket.id,
        user:     @user,
        params:   @ticket_data.merge(
          'article' => @article_data,
        ),
        selector: Setting.get('time_accounting_selector')&.dig('condition') || {},
      )
    end
  end
end
