# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      raise 'no selectors given' if !selectors

      ActiveRecord::Base.transaction(requires_new: true) do
        scope = raw_selectors(selectors, options)

        next [] if scope.nil?

        [
          scope.count(:all).count, # grouped queries count is a hash, not a single digit :(
          scope.limit(limit)
        ]
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error e
        raise ActiveRecord::Rollback
      end
    end

    # @example
    # Ticket.raw_selectors({}, { order_by: 'tickets.state_id ASC' })
    # Ticket.raw_selectors({}, { order_by: [{ column: 'state', direction: 'ASC'}] })
    # Ticket.raw_selectors({}, { order_by: [{ column: 'state', direction: 'ASC'}], locale: 'de-de' })
    def raw_selectors(selectors, options)
      query, bind_params, tables = selector2sql(selectors, options)
      return if !query

      current_user = options[:current_user]
      access = options[:access] || 'full'

      relation = if !current_user || access == 'ignore'
                   Ticket.all
                 else
                   "TicketPolicy::#{access.camelize}Scope".constantize.new(current_user).resolve
                 end

      order_clause = CanSelector::AdvancedSorting.new(options[:order_by], options[:locale], Ticket).calculate_sorting

      relation = relation
        .group('tickets.id')
        .where(query, *bind_params)
        .joins(tables)
        .select('tickets.*')
        .reorder(nil)

      apply_order_onto_relation(relation, order_clause)
    end

    def apply_order_onto_relation(relation, order_clause)
      case order_clause
      when String, Symbol
        relation.order(Arel.sql(order_clause.to_s)) # rubocop:disable Zammad/ActiveRecordReorder
      when Array, Hash
        order_clause = [order_clause] if order_clause.is_a? Hash

        order_clause.reduce(relation) do |memo, elem|
          case elem
          when String, Symbol
            memo.order(Arel.sql(elem)) # rubocop:disable Zammad/ActiveRecordReorder
          when Hash
            memo = memo.select(Arel.sql(elem[:select])) if elem[:select]
            memo = memo.order(Arel.sql(elem[:order])) if elem[:order] # rubocop:disable Zammad/ActiveRecordReorder
            memo = memo.joins(elem[:joins]) if elem[:joins]
            memo = memo.group(elem[:group]) if elem[:group]

            memo
          else
            memo
          end
        end
      else
        relation
      end
    end
  end
end
