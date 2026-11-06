# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sends a ticket's shared draft as it is saved, as an agent sends it from the interface: prepared, confirmed and written
#   as create_article writes an article (CreateArticle::Writing), and the draft deleted with it, as the interface
#   deletes a draft it sent. A draft with files or ticket field changes is left to the interface, which sends them along.
class Service::AI::Tool::SendSharedDraft < Service::AI::Tool
  include Service::AI::Tool::Concerns::ArticleParameters
  include Service::AI::Tool::CreateArticle::Writing

  Draft = Service::AI::Tool::Output::SharedDraft

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  description 'Send the shared draft of a ticket as it is saved, as an agent sends it in Zammad: its type, recipients, ' \
              'subject and text, in reply to the message it answers, with the group\'s email signature. Zammad ' \
              'deletes the draft once it is sent. get_shared_draft reads it first. Where supported the client must ' \
              'confirm the complete prepared message. Otherwise use client tool approval. A draft with files, ticket ' \
              'field changes, or signing or encryption is refused: an agent sends it from Zammad. Do not retry an ' \
              'uncertain write automatically.'
  title 'Send shared draft'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema RECEIPT_SCHEMA
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  mcp_annotations destructive_hint: true, open_world_hint: true
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  time_unit_parameter

  # The draft is read under the ticket's lock, which write_article takes again, so that two calls send it once.
  def execute
    ticket.with_lock do
      draft = Service::AI::Tool::Lookup::SharedDraft.of(ticket, user: current_user)
      next none if draft.nil?

      only_zammad = zammad_only(draft)
      next left_to_zammad(only_zammad) if only_zammad.any?

      write_article(article_arguments(draft)) do |article, outbound|
        draft.destroy!
        article_receipt(article, queued: outbound)
      end
    end
  end

  private

  # The arguments create_article would take for it. A channel takes plain text; the recipients and the subject only
  #   where the article type takes them, as a draft from the interface may keep them for any type.
  def article_arguments(draft)
    article = draft.new_article.with_indifferent_access
    type    = Draft.type_of(article)
    plain   = Service::AI::Tool::CreateArticle::Preparation::Channel.for_type(type).present?

    {
      type:,
      internal:            Draft.internal?(article),
      text:                plain ? Draft.text(draft) : draft.body.to_s,
      content_type:        plain ? 'text/plain' : 'text/html',
      to:                  ([article[:to]] if %w[email sms].include?(type) && article[:to].present?),
      cc:                  ([article[:cc]] if type == 'email' && article[:cc].present?),
      subject:             (article[:subject].presence if type == 'email'),
      reply_to_article_id: replied_article_id(article),
      time_unit:           argument(:time_unit),
      skip_time_accounting: argument(:skip_time_accounting),
    }.compact
  end

  # The interfaces keep the message ID of the message the draft answers: the legacy one as in_reply_to, the desktop one
  #   as inReplyTo.
  def replied_article_id(article)
    message_id = article[:in_reply_to].presence || article[:inReplyTo].presence
    ticket.articles.find_by(message_id:)&.id if message_id
  end

  # Written for the model, like every text a tool returns, so not translated.

  def none
    Service::AI::Tool::Runtime::Result.error('not_found', "Ticket #{ticket.number} has no shared draft. Nothing was sent.")
  end

  # What only Zammad sends along with a draft, as the interface sends it.
  def zammad_only(draft)
    [
      ('files' if draft.attachments.any?),
      ('ticket field changes' if Service::AI::Tool::Lookup::SharedDraft.changed_fields(draft).any?),
      ('signing or encryption' if Service::AI::Tool::Lookup::SharedDraft.secured?(draft)),
    ].compact
  end

  def left_to_zammad(only_zammad)
    Service::AI::Tool::Runtime::Result.error(
      'not_supported',
      "The shared draft of ticket #{ticket.number} has #{only_zammad.to_sentence}, which only Zammad sends along. " \
      'Nothing was sent: an agent sends it from Zammad.'
    )
  end

  # The draft is there still, so nothing is lost.
  def not_confirmed
    Service::AI::Tool::Runtime::Result.error('confirmation_required', "#{Service::MCPServer::Confirmation::NOT_CONFIRMED} The shared draft stays on the ticket for an agent to send from Zammad.")
  end

end
