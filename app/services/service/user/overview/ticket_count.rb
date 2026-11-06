# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How many tickets one of the current user's overviews shows the user: the same tickets as its list
#   (Service::User::Overview::Tickets).
class Service::User::Overview::TicketCount < Service::Base
  requires_current_user!

  attr_reader :overview

  def initialize(overview:)
    @overview = overview
  end

  # @return [Integer]
  def execute
    counted = Service::User::Overview::Tickets
      .with_current_user(current_user)
      .execute(overview:)
      .unscope(:order)
      .count(:all)

    # Counted per ticket, as the overview's query groups by ticket; an overview whose condition cannot be read has no
    #   query and counts as a plain zero.
    counted.is_a?(Hash) ? counted.size : counted
  end
end
