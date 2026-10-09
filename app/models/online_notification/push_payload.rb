# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Builds the message a device shows for an online notification. The service
#   worker has no access to translations, so the text is rendered here in
#   the recipient's locale.
#
# The body uses the source strings and arguments of the activity message
#   builders of the frontend (app/frontend/shared/composables/activity-message),
#   so it says the same as the entry in the notification list and shares its
#   translations. The list's inline markup is not reproduced, a push is plain text.
class OnlineNotification::PushPayload
  MAX_EXCERPT_LENGTH = 100

  # Stand in for the highlight bars until the values are inserted.
  HIGHLIGHT_START = "\u0001".freeze
  HIGHLIGHT_END   = "\u0002".freeze

  TICKET_MESSAGES = {
    'create'                => __('%s created ticket |%s|'),
    'update'                => __('%s updated ticket |%s|'),
    'reminder_reached'      => __('Pending reminder reached for ticket |%s|'),
    'escalation'            => __('Ticket |%s| has escalated!'),
    'escalation_warning'    => __('Ticket |%s| will escalate soon!'),
    'update.merged_into'    => __('Ticket |%s| was merged into another ticket'),
    'update.received_merge' => __('Another ticket was merged into ticket |%s|'),
  }.freeze

  # The events without an actor name only the ticket.
  TICKET_MESSAGES_WITH_ACTOR = %w[create update].freeze

  ARTICLE_MESSAGES = {
    'create'          => __('%s created article for |%s|'),
    'update'          => __('%s updated article for |%s|'),
    'update.reaction' => __('%s reacted with a %s to message from %s |%s|'),
  }.freeze

  KNOWLEDGE_BASE_ANSWER_MESSAGES = {
    'create' => __('Knowledge Base Answer "|%s|" has been created'),
  }.freeze

  STANDALONE_MESSAGES = {
    'bulk_job'                    => __('Bulk action completed for |%s| ticket(s): %s successful, %s failed'),
    'kb_answer_generation_failed' => __('Failed to generate knowledge base draft for "%s": %s'),
  }.freeze

  attr_reader :notification

  def initialize(notification)
    @notification = notification
  end

  def to_h
    {
      title: title,
      body:  body,
      path:  path,
      tag:   tag,
    }
  end

  def ticket
    case related_object
    when Ticket
      related_object
    when Ticket::Article
      related_object.ticket
    end
  end

  private

  # The job runs after the fact, so the object may be gone meanwhile.
  def related_object
    @related_object ||= notification.related_object
  rescue ActiveRecord::RecordNotFound
    @related_object = nil
  end

  # The name the mobile app is installed under, see MobileController#manifest.
  #   What happened, including the ticket title, is in the body.
  def title
    Setting.get('organization').presence || Setting.get('product_name').presence || 'Zammad'
  end

  def body
    template, *args = message

    return translate(__('You have a new notification.')) if template.blank?

    quote_highlights(insert(mark_highlights(translate(template)), args))
  end

  # The bars mark the part the notification list shows in bold. A push is
  #   plain text, so that part is quoted instead. The bars are replaced before
  #   the values are inserted, so a bar inside a ticket title stays.
  def mark_highlights(text)
    bars = text.count('|')
    return text.delete('|') if bars.odd?

    text.gsub('|').with_index { |_bar, index| index.even? ? HIGHLIGHT_START : HIGHLIGHT_END }
  end

  # A counter needs no quotes, and a template that already quotes the part
  #   keeps its own.
  def quote_highlights(text)
    text.gsub(%r{(")?#{HIGHLIGHT_START}(.*?)#{HIGHLIGHT_END}(")?}mo) do
      before, highlight, after = Regexp.last_match.captures
      next "#{before}#{highlight}#{after}" if (before && after) || highlight.match?(%r{\A\d+\z})

      "#{before}\"#{highlight}\"#{after}"
    end
  end

  # Fills the placeholders one by one like the frontend translator does, so a
  #   translation with a literal % or a different placeholder count cannot
  #   break the message.
  def insert(text, args)
    args.reduce(text) do |result, arg|
      next result if arg.nil?

      result.sub('%s') { arg.to_s }
    end
  end

  def message
    case related_object
    when Ticket
      ticket_message
    when Ticket::Article
      article_message
    when KnowledgeBase::Answer::Translation
      [KNOWLEDGE_BASE_ANSWER_MESSAGES[type_name], related_object.title.presence || '-']
    when OnlineNotificationStandalone
      standalone_message
    end
  end

  def ticket_message
    template = TICKET_MESSAGES[type_name]
    title    = ticket.title.presence || '-'

    return [template, actor_name, title] if TICKET_MESSAGES_WITH_ACTOR.include?(type_name)

    [template, title]
  end

  def article_message
    template = ARTICLE_MESSAGES[type_name]
    return [template, actor_name, ticket.title.presence || '-'] if type_name != 'update.reaction'

    reaction = related_object.preferences.dig('whatsapp', 'reaction') || {}

    [template, reaction['author'].presence || '-', reaction['emoji'].presence || '-', actor_name, article_excerpt.presence || '-']
  end

  def standalone_message
    data = related_object.data.to_h.with_indifferent_access

    case related_object.kind
    when 'bulk_job'
      total  = data[:total].to_i
      failed = data[:failed_count].to_i

      [STANDALONE_MESSAGES['bulk_job'], total, total - failed, failed]
    when 'kb_answer_generation_failed'
      [STANDALONE_MESSAGES['kb_answer_generation_failed'], data[:ticket_title], data[:error_message]]
    end
  end

  # Same steps as textCleanup and textTruncate of the frontend, which count in
  #   UTF-16 code units; a surrogate pair is never split here.
  def article_excerpt
    text = related_object.body.to_s.strip
      .gsub(%r{\r\n|\n\r}, "\n")
      .tr("\r", "\n")
      .gsub(" \n", "\n")
      .gsub(%r{\n{3,20}}, "\n\n")
      .gsub(%r{<([^>]+)>}, '')

    units = text.encode('UTF-16LE')
    return text if units.bytesize / 2 < MAX_EXCERPT_LENGTH

    cut = units.byteslice(0, MAX_EXCERPT_LENGTH * 2)
    cut = cut.byteslice(0, cut.bytesize - 2) if cut.byteslice(-2, 2).unpack1('v').between?(0xD800, 0xDBFF)

    "#{cut.force_encoding('UTF-16LE').encode('UTF-8')}…"
  end

  def type_name
    notification.type&.name.to_s
  end

  def actor_name
    notification.created_by&.fullname.presence || '-'
  end

  def path
    return '/notifications' if ticket.blank?

    ticket_path = "/tickets/#{ticket.id}"
    return ticket_path if !related_object.is_a?(Ticket::Article)

    "#{ticket_path}#article-#{related_object.id}"
  end

  def tag
    notification.push_tag
  end

  def translate(string)
    Translation.translate(notification.user.locale, string)
  end
end
