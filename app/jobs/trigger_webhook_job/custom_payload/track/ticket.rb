# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Ticket < TriggerWebhookJob::CustomPayload::Track
  def self.root?
    true
  end

  def self.klass
    'Ticket'
  end

  def self.functions
    klass.constantize.attribute_names + %w[
      created_by
      current_state_color
      customer
      group
      organization
      owner
      priority
      state
      updated_by
    ].freeze
  end

  def self.replacements(pre_defined_webhook_type:)
    user_functions = TriggerWebhookJob::CustomPayload::Track::User.functions
    {
      ticket:                functions,
      'ticket.priority':     TriggerWebhookJob::CustomPayload::Track::Ticket::Priority.functions,
      'ticket.state':        TriggerWebhookJob::CustomPayload::Track::Ticket::State.functions,
      'ticket.group':        TriggerWebhookJob::CustomPayload::Track::Group.functions,
      'ticket.owner':        user_functions,
      'ticket.customer':     user_functions,
      'ticket.updated_by':   user_functions,
      'ticket.created_by':   user_functions,
      'ticket.organization': TriggerWebhookJob::CustomPayload::Track::Organization.functions,
    }
  end
end
