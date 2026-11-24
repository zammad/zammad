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
    Service::User::Overview::Tickets
      .with_current_user(current_user)
      .execute(overview:)
      .count_rows
  end
end
