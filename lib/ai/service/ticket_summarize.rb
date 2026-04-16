# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Service::TicketSummarize < AI::Service
  def self.lookup_attributes(context_data, locale)
    {
      identifier:     'ticket_summarize',
      locale:,
      related_object: context_data[:ticket],
    }
  end

  def self.lookup_version(context_data, _locale)
    context_data[:articles].cache_version(:created_at)
  end

  def persistable?
    true
  end

  def analytics?
    true
  end

  # It can happen that in rare situations that the conversation summary is returned
  # as a string, improve the situation with a small mapper.
  def post_transform_result(result)
    conversation_summary = result['conversation_summary']
    return result if conversation_summary.is_a?(Array)

    result['conversation_summary'] = Array(conversation_summary)
    result
  end

  def validate_result!(result)
    raise InvalidResultKeysError if !result.key?('language')

    required_keys = %w[
      customer_request
      conversation_summary
    ]

    raise InvalidResultKeysError if !required_keys.intersect?(result.keys)
  end

  private

  def options
    {
      temperature: 0.1,
    }
  end
end
