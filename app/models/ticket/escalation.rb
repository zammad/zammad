# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'escalation'

module Ticket::Escalation
  extend ActiveSupport::Concern

  included do
    after_commit :update_escalation_information
  end

=begin

rebuild escalations for all open tickets

  result = Ticket::Escalation.rebuild_all

returns

  result = true

=end

  def self.rebuild_all
    ActiveSupport::Deprecation.warn("Method 'rebuild_all' is deprecated. Run `TicketEscalationRebuildJob.perform_now` instead")

    TicketEscalationRebuildJob.perform_now
  end

=begin

rebuild escalation for ticket

  ticket = Ticket.find(123)
  result = ticket.escalation_calculation

returns

  result = true # true = ticket has been updated | false = no changes on ticket

=end

  def escalation_calculation(force = false)
    ::Escalation.new(self, force: force).calculate!
  end

  private

  def update_escalation_information
    # return if we run import mode
    return if Setting.get('import_mode')

    # return if ticket was destroyed in this transaction
    return if destroyed?

    return if callback_loop

    # needs to operate on a copy because otherwise caching breaks
    record_copy = Ticket.find_by(id: id)
    return if !record_copy

    record_copy.callback_loop = true

    # needs saving explicitly because this is after_commit!
    record_copy.escalation_calculation
  end
end
