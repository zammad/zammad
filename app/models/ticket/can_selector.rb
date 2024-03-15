# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Ticket::CanSelector
  extend ActiveSupport::Concern

  include ::CanSelector

  class_methods do
=begin

get count of tickets and tickets which match on selector

@param  [Hash] selectors hash with conditions
@oparam [Hash] options

@option options [String]  :access can be 'full', 'read', 'create' or 'ignore' (ignore means a selector over all tickets), defaults to 'full'
@option options [Integer] :limit of tickets to return
@option options [User]    :user is a current user
@option options [Integer] :execution_time is a current user

@return [Integer, [<Ticket>]]

@example
  ticket_count, tickets = Ticket.selectors(params[:condition], limit: limit, current_user: current_user, access: 'full')

  ticket_count # count of found tickets
  tickets      # tickets

=end

    def selectors(selectors, options = {})
      limit = options[:limit] || 10
      current_user = options[:current_user]
      access = options[:access] || 'full'
      raise 'no selectors given' if !selectors

      query, bind_params, tables = selector2sql(selectors, options)
      return [] if !query

      ActiveRecord::Base.transaction(requires_new: true) do

        relation = if !current_user || access == 'ignore'
                     Ticket.all
                   else
                     "TicketPolicy::#{access.camelize}Scope".constantize.new(current_user).resolve
                   end

        tickets = relation
          .distinct
          .where(query, *bind_params)
          .joins(tables)
          .reorder(options[:order_by])

        [tickets.count, tickets.limit(limit)]
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error e
        raise ActiveRecord::Rollback
      end
    end
  end
end
