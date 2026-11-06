# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A reply as an article would be prepared for it, but kept as a shared draft for an agent to send later from Zammad:
#   checked by the same rules for type, recipients and text, and stored in the keys the desktop and the legacy
#   interface apply. What Zammad adds when the agent sends — the sender, the signature, the channel's destination —
#   is left to that moment, as for a draft an agent saves in the interface.
class Service::AI::Tool::SaveSharedDraft::Content < Service::AI::Tool::CreateArticle::Preparation
  # @return [Hash] the draft's new article
  def execute
    validate_input
    prepare_type

    new_article
  end

  private

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString

  # A type the interface would not offer on this ticket is refused, as an agent could not send the draft in it.
  def prepare_type
    if type == 'email'
      invalid('The ticket group has no active email sender. Configure it in Zammad first.') if !ticket.group.email_address&.active?
      prepare_email_recipients
      check_subject
    elsif channel_class
      check_channel
    elsif RECORD_TYPES.exclude?(type)
      invalid("Zammad has no available outbound delivery for #{type}. Use a supported channel or save a note.")
    end
  end

  # What the channel asks of the text and the recipient holds for the draft too; its destination is left to the moment
  #   the agent sends.
  def check_channel
    active_channel
    channel_class.check(ticket:, arguments:)
    data[:to] = channel_class.recipient(arguments)
  end

  def check_subject
    invalid('The subject must be one line.') if arguments[:subject]&.match?(%r{[\r\n]})
  end

  # rubocop:enable Zammad/DetectTranslatableString

  # The desktop interface reads the type from articleType, the legacy one from type; both take the recipients as one
  #   line each.
  def new_article
    {
      'articleType' => type,
      'type'        => type,
      'internal'    => arguments[:internal] || false,
      'body'        => html_body,
      'to'          => Array(data[:to]).join(', '),
      'cc'          => Array(data[:cc]).join(', '),
      'subject'     => arguments[:subject].presence,
    }.compact
  end
end
