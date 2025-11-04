# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# This service save a ticket with most of validations and all calbacks like triggers.
# But it skips custom object attributes validations.
# This is needed to allow changing of some attributes even if a required custom object attribute is missing.
# For example when editing title or customer of an old ticket that did not have a required custom object attribute at that time.
# https://github.com/zammad/zammad/issues/4417
class Service::Ticket::ForcedUpdate < Service::Base
  attr_reader :ticket, :update_data

  def initialize(ticket, update_data)
    super()

    @ticket      = ticket
    @update_data = update_data
  end

  def execute
    ApplicationHandleInfo.in_context(:forced_update) do
      ticket.with_lock do
        ticket.update!(update_data)
      end
    end

    ticket
  end
end
