# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator
  class TimeAccounting < Base

    def valid!
      return if !Setting.get('time_accounting')
      # Only kick in if an article was actually created.
      return if @article_data.blank?
      return if @article_data[:time_unit].present?
      return if !TicketPolicy.new(@user, @ticket).agent_update_access?
      return if !time_accounting_condition_matches?

      raise Error
    end

    class Error < Service::Ticket::Update::Validator::BaseError
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
        params:   params,
        selector: Setting.get('time_accounting_selector')&.dig('condition') || {},
      )
    end

    # In GraphQL context, all IDs are transformed into corresponding records.
    #   However, Core Workflow expects only record names as param values, and will try to lookup the correct IDs.
    #   Therefore, here we map them back to IDs in order to skip this lookup mechanism,
    #   since all information is present at this point.
    def params
      { 'id' => @ticket.id }.merge(
        map_to_ids(@ticket_data).merge(
          'article' => map_to_ids(@article_data),
        )
      )
    end

    def map_to_ids(input)
      {}.tap do |data|

        input.each do |key, value|
          if !value.is_a?(ApplicationModel::CanLookup)
            data[key] = value
            next
          end

          next if ticket_data["#{key}_id"].present?

          data["#{key}_id"] = value.id
        end
      end
    end
  end
end
