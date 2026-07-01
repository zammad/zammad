# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Ticket::EmbedSummary < Service::AI::Ticket::EmbedBase

  requires_current_user!

  def initialize(ticket:, locale: nil)
    super(ticket:)
    @locale = locale
  end

  # Embeds the ticket summary, generating it via the Summarize service if it is not stored yet (this
  # runs inside a background job, so generating inline is fine). Returns nil when no summary can be
  # produced (e.g. the summary feature is disabled). Raises ContentTooLargeError if the summary is
  # too large to embed.
  #
  # @return [Array<Numeric>, nil]
  def execute
    result = Service::Ticket::AIAssistance::Summarize
      .with_current_user(current_user)
      .execute(ticket:, locale:)

    return nil if result.nil?

    content = build_content(result)
    check_content_size!(content)

    Service::AI::VectorDB::Embedding.execute(input: content)
  end

  private

  def locale
    @locale || current_user.locale
  end

  def build_content(result)
    parts = [ticket.title]

    customer_request = result.content['customer_request']
    parts << customer_request if customer_request.present?

    Array(result.content['conversation_summary']).each do |item|
      parts << item if item.present?
    end

    parts.join("\n\n")
  end
end
