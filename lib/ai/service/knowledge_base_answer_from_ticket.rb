# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Service::KnowledgeBaseAnswerFromTicket < AI::Service
  def self.lookup_attributes(context_data, locale)
    {
      identifier:     'knowledge_base_answer_from_ticket',
      locale:,
      related_object: context_data[:ticket]
    }
  end

  def self.lookup_version(context_data, _locale)
    context_data[:articles].cache_version(:created_at)
  end

  def analytics?
    true
  end

  def validate_result!(result)
    required_keys = %w[title body category_id]

    raise InvalidResultKeysError if !required_keys.all? { |key| result[key].present? }
  end

  def options
    {
      temperature: 0.1,
    }
  end
end
