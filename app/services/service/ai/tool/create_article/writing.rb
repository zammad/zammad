# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How a tool writes an article: on the locked ticket, as the user may change it, prepared and confirmed where the
#   article asks for it — for create_article, and for a tool that presets its arguments, such as a note.
module Service::AI::Tool::CreateArticle::Writing
  TIME_UNIT_NAMES = { 'minute' => 'minutes', 'hour' => 'hours', 'quarter' => 'quarter hours', 'day' => 'days' }.freeze

  # What a tool that writes an article as it is asked answers.
  RECEIPT_SCHEMA = {
    type:       'object',
    properties: {
      article_id:    { type: 'integer' },
      ticket_id:     { type: 'integer' },
      ticket_number: { type: 'string' },
      url:           { type: 'string' },
      type:          { type: 'string' },
      internal:      { type: 'boolean' },
      to:            { type: 'string' },
      cc:            { type: 'string' },
      outcome:       { type: 'string', enum: %w[saved queued] },
    },
    required:   %w[article_id ticket_id ticket_number url type internal to cc outcome],
  }.freeze

  # @param arguments [Hash] the arguments of create_article
  # @yield [article, outbound] the saved article, and whether it goes out
  # @return [Service::AI::Tool::Runtime::Result] the block's receipt, the confirmation asked for, or the refusal
  def write_article(arguments)
    ticket.with_lock do
      prepared = Service::AI::Tool::CreateArticle::Preparation.execute(ticket:, user: current_user, arguments:)
      response = confirmation&.call(**prepared.fetch(:confirmation), declined: not_confirmed)
      next response if response

      article = Service::Ticket::Article::Create.execute(current_user:, ticket:, article_data: prepared.fetch(:article_data))
      yield article, prepared.fetch(:outbound)
    end
  rescue Service::AI::Tool::CreateArticle::Preparation::InvalidArticle => e
    Service::AI::Tool::Runtime::Result.error('invalid_arguments', e.message)
  rescue Service::Ticket::Update::Validator::TimeAccounting::Error
    # Written for the model, like every text a tool returns, so not translated.
    Service::AI::Tool::Runtime::Result.error(
      'invalid_arguments',
      "This ticket asks for the time spent on it. Ask the user once: give the time they name as time_unit#{time_unit_name}, never an estimate, " \
      'or skip_time_accounting: true where they account none.'
    )
  end

  private

  def article_receipt(article, queued:)
    content = {
      article_id:    article.id,
      ticket_id:     ticket.id,
      ticket_number: ticket.number,
      url:           Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id),
      type:          article.type.name,
      internal:      article.internal,
      to:            article.to.to_s,
      cc:            article.cc.to_s,
      outcome:       queued ? 'queued' : 'saved',
    }
    Service::AI::Tool::Runtime::Result.ok(content)
  end

  # What still gets the message to the customer where the form was declined, also by a client that never shows it.
  def not_confirmed
    return if !ticket.group&.shared_drafts

    # Written for the model, like every text a tool returns, so not translated.
    Service::AI::Tool::Runtime::Result.error('confirmation_required', "#{Service::MCPServer::Confirmation::NOT_CONFIRMED} Offer to save the message as the ticket's shared draft with save_shared_draft, for an agent to send from Zammad.")
  end

  # The unit Zammad shows next to its time field; none where it is not configured.
  def time_unit_name
    unit = Setting.get('time_accounting_unit')
    name = unit == 'custom' ? Setting.get('time_accounting_unit_custom').presence : TIME_UNIT_NAMES[unit]
    " in #{name}" if name
  end
end
