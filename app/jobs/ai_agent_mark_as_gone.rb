# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AIAgentMarkAsGone < ApplicationJob
  def lock_key
    @ticket = arguments[1]

    # "AIAgentMarkAsGone/Ticket/42
    "#{self.class.name}/Ticket/#{ticket.id}"
  end

  def perform(ticket)
    ticket.with_lock do
      ticket.ai_agent_running = AI::Agent.working_on_ticket?(ticket)
      ticket.save!
    end
  end
end
