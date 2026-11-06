# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A ticket's shared draft in a tool's result: the reply an agent saved to send later. Its facts — type, recipients, who
#   saved it — are short enough for every read of the ticket; its text comes only where it is asked for, marked as an
#   agent's, as an agent or a tool for one wrote it.
class Service::AI::Tool::Output::SharedDraft < Service::AI::Tool::Output
  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  SCHEMA = {
    type:       'object',
    properties: {
      id:               { type: 'integer' },
      type:             { type: 'string', description: 'The article type it is sent as.' },
      internal:         { type: 'boolean' },
      to:               { type: 'string' },
      cc:               { type: 'string' },
      subject:          { type: 'string' },
      saved_by:         Service::AI::Tool::Output::User::SCHEMA,
      updated_at:       { type: 'string', format: 'date-time' },
      attachment_count: { type: 'integer', description: 'Its files, which only Zammad sends with it.' },
      ticket_fields:    { type: 'boolean', description: 'It changes ticket fields as well when an agent sends it in Zammad.' },
      secured:          { type: 'boolean', description: 'The agent chose to sign or encrypt it, which only Zammad does when an agent sends it.' },
    },
    required:   %w[id type internal saved_by updated_at],
  }.freeze

  class << self
    # Its facts, without its text.
    def summary(draft)
      content = facts(draft)

      build_part(content:, text: AI::PromptText.xml_text("Shared draft: #{line(content)}."))
    end

    # Its facts in a line, without its text.
    def facts_text(draft)
      line(facts(draft))
    end

    # Its text, as plain text with the address of each link, as a channel sends it.
    def text(draft)
      draft.body.to_s.html2text
    end

    # Its text for a client to read: a reply may quote a customer's mail, whose styles may hide text, which a message is
    #   read without as well.
    def readable_text(draft)
      AI::HiddenText.remove_from_html(draft.body.to_s).html2text
    end

    def marked_text(text)
      AI::PromptText.marked_text(text, source: 'agent', field: 'shared_draft')
    end

    # An article as a draft keeps it, in a few words: its type, recipients and subject.
    #
    # @param article [Hash] a draft's new article, in the keys of either interface
    def article_summary(article)
      article = article.with_indifferent_access

      [
        type_of(article) || 'unknown type',
        ('internal' if internal?(article)),
        ("to #{article[:to]}" if article[:to].present?),
        ("cc #{article[:cc]}" if article[:cc].present?),
        ("subject \"#{article[:subject]}\"" if article[:subject].present?),
      ].compact.join(', ')
    end

    # The desktop interface keeps the type as articleType, the legacy one as type.
    def type_of(article)
      article[:articleType].presence || article[:type].presence
    end

    # The legacy interface may keep it as a string.
    def internal?(article)
      ActiveModel::Type::Boolean.new.cast(article[:internal]) || false
    end

    # Its files, inline images too: the text refers to them, so only Zammad sends the draft with them.
    def attachment_count(draft)
      draft.attachments.size
    end

    private

    def facts(draft)
      article = draft.new_article.with_indifferent_access

      {
        id:               draft.id,
        type:             type_of(article),
        internal:         internal?(article),
        to:               article[:to].presence,
        cc:               article[:cc].presence,
        subject:          article[:subject].presence,
        saved_by:         Service::AI::Tool::Output::User.row(draft.updated_by).content,
        updated_at:       draft.updated_at,
        attachment_count: attachment_count(draft).nonzero?,
        ticket_fields:    (true if Service::AI::Tool::Lookup::SharedDraft.changed_fields(draft).any?),
        secured:          (true if Service::AI::Tool::Lookup::SharedDraft.secured?(draft)),
      }.compact
    end

    # Written for the model, like every text a tool returns, so not translated.
    def line(content)
      count = content[:attachment_count]

      [
        article_summary(content),
        "saved by #{content.dig(:saved_by, :name)} at #{time(content[:updated_at])}",
        ("#{count} #{'file'.pluralize(count)}" if count),
        ('with ticket field changes' if content[:ticket_fields]),
        ('signed or encrypted' if content[:secured]),
      ].compact.join(' · ')
    end
  end
end
