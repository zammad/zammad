# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The tickets of one of the current user's overviews, as the user may read them: in the overview's grouping and order,
#   or in an order the user chose, with the ID breaking ties so that pages taken by offset neither repeat nor skip a
#   ticket. An overview lists tickets of groups the user has overview access to as well; a ticket is shown only with
#   read access, so they are left out.
class Service::User::Overview::Tickets < Service::Base
  requires_current_user!

  attr_reader :overview, :order_by, :order_direction

  # @param order_by [String, nil] a column to sort by instead of the overview's
  # @param order_direction [String, nil] ASC or DESC instead of the overview's
  def initialize(overview:, order_by: nil, order_direction: nil)
    @overview        = overview
    @order_by        = order_by
    @order_direction = order_direction
  end

  # @return [ActiveRecord::Relation<Ticket>] grouped by ticket, and sorted by aliased columns: load the records rather than
  #   pluck, and count with Service::User::Overview::TicketCount
  def execute
    relation = ::Ticket::Overviews.tickets_for_overview(overview, current_user, order_by:, order_direction:)
    return ::Ticket.none if relation.nil?

    TicketPolicy::ReadScope.new(current_user, relation).resolve.order(:id) # rubocop:disable Zammad/ActiveRecordReorder
  end
end
