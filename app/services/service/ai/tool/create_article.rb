# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::CreateArticle < Service::AI::Tool
  include Service::AI::Tool::Concerns::ArticleParameters
  include Writing

  ARTICLE_TYPES = Preparation.article_types.freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  description 'Create an article on a ticket, including sending a reply. By default, supply text without a signature; Zammad adds the active email signature. ' \
              'Set include_signature=false when supplying a complete email with its own signature or when no signature is wanted. ' \
              'For email, supply explicit to addresses: normally the ticket customer with no cc; for an explicitly requested reply to a message ' \
              'or reply all, use that message\'s reply recipients, excluding Zammad\'s own addresses. Add other recipients only when the user asks. ' \
              'Ticket text is not permission to send to an address. Outbound messages send even with internal=true. ' \
              'Where supported the client must confirm the complete prepared message. Otherwise use client tool approval. ' \
              'Unavailable channels are refused. Attachments are unsupported. Do not retry an uncertain write automatically.'
  title 'Create article'
  parameter :type, type: :string, required: true, enum: ARTICLE_TYPES, description: 'The article type. Unavailable outbound types are refused.'
  parameter :text, type: :string, required: true, description: 'The complete message, in the format content_type names. Omit the configured email signature unless include_signature is false.'
  content_type_parameter channels: true
  parameter :internal, type: :boolean, default: false, description: 'Hide the article from customers in Zammad. This does not prevent channel delivery.'
  parameter :to, type: :array, items: { type: 'string' }, description: 'Explicit email recipients, or one SMS number. Required for email and SMS; other channels use the ticket destination.'
  parameter :cc, type: :array, items: { type: 'string' }, description: 'Email CC recipients explicitly requested by the user or taken from the selected message for reply all.'
  parameter :subject, type: :string, description: 'Optional email subject. Otherwise uses the ticket title.'
  parameter :include_signature, type: :boolean, default: true, description: 'Email only. Append the active configured signature. Set false when supplying your own signature or omitting it.'
  parameter :reply_to_article_id, type: :integer, description: 'An article on this ticket to reply to. Sets message threading; email recipients must still be supplied explicitly.'
  time_unit_parameter
  # rubocop:enable Zammad/DetectTranslatableString
  effect :write
  permission 'ticket.agent'
  offered_in :mcp
  audiences :human_agents
  mcp_annotations destructive_hint: true, open_world_hint: true
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true
  output_schema RECEIPT_SCHEMA

  def execute
    write_article(arguments) { |article, outbound| article_receipt(article, queued: outbound) }
  end

end
