# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OnlineNotification::PushPayload do
  subject(:payload) { described_class.new(notification).to_h }

  let(:agent)        { create(:agent) }
  let(:actor)        { create(:agent, firstname: 'Rosa', lastname: 'Luxemburg') }
  let(:ticket)       { create(:ticket, title: 'Printer is on fire') }
  let(:type_name)    { 'update' }
  let(:notification) { create(:online_notification, o: ticket, type_name:, user_id: agent.id, created_by_id: actor.id) }
  let(:app_name)     { Setting.get('organization').presence || Setting.get('product_name') }

  it 'describes a ticket update like the notification list' do
    expect(payload).to eq(
      title: app_name,
      body:  'Rosa Luxemburg updated ticket "Printer is on fire"',
      path:  "/tickets/#{ticket.id}",
      tag:   "ticket-#{ticket.id}",
    )
  end

  context 'with the other ticket events' do
    {
      'create'                => 'Rosa Luxemburg created ticket "Printer is on fire"',
      'reminder_reached'      => 'Pending reminder reached for ticket "Printer is on fire"',
      'escalation'            => 'Ticket "Printer is on fire" has escalated!',
      'escalation_warning'    => 'Ticket "Printer is on fire" will escalate soon!',
      'update.merged_into'    => 'Ticket "Printer is on fire" was merged into another ticket',
      'update.received_merge' => 'Another ticket was merged into ticket "Printer is on fire"',
    }.each do |event, text|
      context "with #{event}" do
        let(:type_name) { event }

        it 'renders the text of the notification list' do
          expect(payload[:body]).to eq(text)
        end
      end
    end
  end

  context 'with an article' do
    let(:article)      { create(:ticket_article, ticket:) }
    let(:article_type) { 'create' }
    let(:notification) { create(:online_notification, o: article, type_name: article_type, user_id: agent.id, created_by_id: actor.id) }

    it 'links to the article inside the ticket', :aggregate_failures do
      expect(payload).to eq(
        title: app_name,
        body:  'Rosa Luxemburg created article for "Printer is on fire"',
        path:  "/tickets/#{ticket.id}#article-#{article.id}",
        tag:   "ticket-#{ticket.id}",
      )
    end

    context 'when it was updated' do
      let(:article_type) { 'update' }

      it 'renders the text of the notification list' do
        expect(payload[:body]).to eq('Rosa Luxemburg updated article for "Printer is on fire"')
      end
    end

    context 'when somebody reacted to it' do
      let(:article_type) { 'update.reaction' }
      let(:article) do
        create(:ticket_article, ticket:, content_type: 'text/html', body: "<p>The printer in room 3 #{'is burning ' * 12}</p>",
                                preferences: { whatsapp: { reaction: { author: 'Nicole Braun', emoji: '👍' } } })
      end

      it 'names who reacted, with what and to whose message' do
        expect(payload[:body]).to start_with('Nicole Braun reacted with a 👍 to message from Rosa Luxemburg "The printer in room 3')
      end

      it 'cuts the quoted message without markup after 100 characters like the notification list', :aggregate_failures do
        excerpt = payload[:body].delete_prefix('Nicole Braun reacted with a 👍 to message from Rosa Luxemburg "').delete_suffix('"')

        expect(excerpt).to start_with('The printer in room 3 is burning')
        expect(excerpt.length).to eq(101)
        expect(excerpt).to end_with('…')
        expect(excerpt).not_to include('<p>')
      end

      context 'when the cut would split an emoji' do
        let(:article) do
          create(:ticket_article, ticket:, body: "#{'a' * 99}😀 and more",
                                  preferences: { whatsapp: { reaction: { author: 'Nicole Braun', emoji: '👍' } } })
        end

        it 'cuts before the emoji, counting like the notification list' do
          expect(payload[:body]).to end_with(" \"#{'a' * 99}…\"")
        end
      end
    end
  end

  context 'with a generated knowledge base answer' do
    let(:translation)  { create(:knowledge_base_answer_translation, title: 'How to put out a printer fire') }
    let(:notification) { create(:online_notification, o: translation, type_name: 'create', user_id: agent.id, created_by_id: 1) }

    it 'names the answer and opens the notification list' do
      expect(payload).to eq(
        title: app_name,
        body:  'Knowledge Base Answer "How to put out a printer fire" has been created',
        path:  '/notifications',
        tag:   "online-notification-#{notification.id}",
      )
    end
  end

  context 'with a finished bulk action' do
    let(:notification) { create(:online_notification, :with_bulk_job, user_id: agent.id, created_by_id: 1) }

    it 'reports the counts and opens the notification list' do
      expect(payload).to eq(
        title: app_name,
        body:  'Bulk action completed for 123 ticket(s): 115 successful, 8 failed',
        path:  '/notifications',
        tag:   "online-notification-#{notification.id}",
      )
    end
  end

  context 'with a failed knowledge base answer generation' do
    let(:standalone)   { create(:online_notification_standalone, :kb_answer_generation_failed) }
    let(:notification) { create(:online_notification, o: standalone, type_name: 'kb_answer_generation_failed', user_id: agent.id, created_by_id: 1) }

    it 'names the ticket and the error' do
      expect(payload[:body]).to eq('Failed to generate knowledge base draft for "Example ticket": AI service unavailable')
    end
  end

  context 'with a bar in the ticket title' do
    let(:ticket) { create(:ticket, title: 'Printer | Scanner') }

    # The notification list would read the bar as markup, a push stays plain text.
    it 'quotes the title and keeps its bar' do
      expect(payload[:body]).to eq('Rosa Luxemburg updated ticket "Printer | Scanner"')
    end
  end

  context 'when the organization is not set' do
    before { Setting.set('organization', '') }

    it 'uses the product name as title like the app manifest' do
      expect(payload[:title]).to eq(Setting.get('product_name'))
    end
  end

  context 'with an unknown notification type' do
    let(:type_name) { 'something_new' }

    it 'falls back to a generic message' do
      expect(payload[:body]).to eq('You have a new notification.')
    end
  end

  context 'when the related object no longer exists' do
    before { ticket.destroy! }

    it 'points to the notification list' do
      expect(payload).to eq(
        title: app_name,
        body:  'You have a new notification.',
        path:  '/notifications',
        tag:   "online-notification-#{notification.id}",
      )
    end
  end

  context 'when the recipient uses another locale' do
    let(:agent)  { create(:agent, preferences: { locale: 'de-de' }) }
    let(:target) { '%s hat das Ticket |%s| aktualisiert' }

    before do
      Translation.find_or_initialize_by(locale: 'de-de', source: '%s updated ticket |%s|')
        .update!(target:, created_by_id: 1, updated_by_id: 1)
    end

    it 'uses the translation of the notification list' do
      expect(payload[:body]).to eq('Rosa Luxemburg hat das Ticket "Printer is on fire" aktualisiert')
    end

    context 'when the translation contains a literal percent sign' do
      let(:target) { '%s hat das Ticket |%s| zu 100% aktualisiert' }

      it 'keeps it' do
        expect(payload[:body]).to eq('Rosa Luxemburg hat das Ticket "Printer is on fire" zu 100% aktualisiert')
      end
    end

    context 'when the translation has more placeholders than values' do
      let(:target) { '%s hat das Ticket |%s| für %s aktualisiert' }

      it 'leaves the extra placeholder like the notification list' do
        expect(payload[:body]).to eq('Rosa Luxemburg hat das Ticket "Printer is on fire" für %s aktualisiert')
      end
    end
  end

  describe 'message tables' do
    let(:builders) do
      Rails.root.glob('app/frontend/shared/composables/activity-message/activityMessageBuilder/builders/*.ts').map(&:read).join
    end

    let(:templates) do
      [
        described_class::TICKET_MESSAGES,
        described_class::ARTICLE_MESSAGES,
        described_class::KNOWLEDGE_BASE_ANSWER_MESSAGES,
        described_class::STANDALONE_MESSAGES,
      ].flat_map(&:values)
    end

    it 'uses the source strings of the notification list', :aggregate_failures do
      templates.each do |template|
        expect(builders).to include("'#{template}'"), "#{template.inspect} is not a string of the activity message builders"
      end
    end

    it 'has a message for every event the notification list describes', :aggregate_failures do
      {
        'ticket.ts'                => described_class::TICKET_MESSAGES,
        'ticket-article.ts'        => described_class::ARTICLE_MESSAGES,
        'knowledge-base-answer.ts' => described_class::KNOWLEDGE_BASE_ANSWER_MESSAGES,
      }.each do |builder, messages|
        events = Rails.root.join('app/frontend/shared/composables/activity-message/activityMessageBuilder/builders', builder)
          .read
          .scan(%r{case '([^']+)':})
          .flatten

        expect(messages.keys).to match_array(events), "the push messages differ from the events of #{builder}"
      end
    end

    it 'has a message for every kind of standalone notification' do
      kinds = OnlineNotificationStandalone.validators_on(:kind).flat_map { it.options[:in].to_a }

      expect(described_class::STANDALONE_MESSAGES.keys).to match_array(kinds)
    end
  end
end
