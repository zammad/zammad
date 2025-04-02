# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Ticket::Article < TriggerWebhookJob::CustomPayload::Track

  def self.root?
    true
  end

  def self.klass
    'Ticket::Article'
  end

  def self.functions
    super + %w[
      created_by
      updated_by
      type
      sender
      origin_by
    ].freeze
  end

  def self.replacements(pre_defined_webhook_type:)
    user_functions = TriggerWebhookJob::CustomPayload::Track::User.functions
    {
      article:              functions,
      'article.sender':     TriggerWebhookJob::CustomPayload::Track::Ticket::Article::Sender.functions,
      'article.type':       TriggerWebhookJob::CustomPayload::Track::Ticket::Article::Type.functions,
      'article.created_by': user_functions,
      'article.updated_by': user_functions,
    }
  end
end
