# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Article translation', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:group)    { create(:group) }
  let(:auto)     { false }
  # German as the translation target, not as the interface language: every string this spec clicks
  # and reads is the English source, which a loaded German catalog would replace.
  let(:agent)    { create(:agent, groups: [group], preferences: { content_translation_target_locale: 'de-de', content_translation_auto: auto }) }
  let(:ticket)   { create(:ticket, group:) }
  let(:locale)   { Locale.find_by(locale: 'de-de') }
  let(:articles) { [create(:ticket_article, ticket:, body: 'Hello world.', content_type: 'text/plain'), create(:ticket_article, ticket:, body: 'How are you?', content_type: 'text/plain')] }

  # Stored translations, so the round trip does not depend on a translation service answering.
  def store_translations
    translations = ['Hallo Welt.', 'Wie geht es dir?']
    articles.each_with_index do |article, index|
      translation = translations[index] || "Übersetzter Beitrag #{index + 1}"
      Service::ContentTranslation::StoredTranslation.save(
        object:      article,
        locale:,
        content:     article.body,
        html:        false,
        backend:     'ai',
        translation:,
      )
    end
  end

  before do
    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider
    setup_content_translation
    Setting.set('content_translation_ticket_article_auto', true)

    store_translations

    visit "/ticket/#{ticket.id}"
    wait_for_gql('shared/entities/ticket/graphql/queries/ticket/articles.graphql')
  end

  # Both header variants render the menu; the full one is the visible one here.
  def open_translation_menu(trigger = 'Translation to Deutsch - German')
    within '[data-test-id="ticket-detail-top-bar-full-details"]' do
      click_on trigger
    end
  end

  context 'when an article arrives with the mode on', performs_jobs: true do
    before do
      allow_any_instance_of(AI::Provider::ZammadAI).to receive(:ask).and_return('Gibt es etwas Neues?')
    end

    it 'translates it without the agent doing anything' do
      open_translation_menu

      find('[data-test-id="translate-all-articles"]').click

      expect(page).to have_text('Hallo Welt.')

      perform_enqueued_jobs(only: ContentTranslationJob) do
        create(:ticket_article, ticket:, body: 'Anything new?', content_type: 'text/plain')

        expect(page).to have_text('Gibt es etwas Neues?')
      end
    end
  end

  context 'with the personal setting already on' do
    let(:auto) { true }

    it 'translates the ticket on opening it' do
      expect(page).to have_text('Hallo Welt.').and(have_text('Wie geht es dir?'))
    end

    it 'shows the switch as on' do
      open_translation_menu('All articles translated to Deutsch - German')

      expect(find('[data-test-id="translate-all-articles"]')).to match_selector('[aria-checked="true"]')
    end
  end

  context 'with older articles outside the initial page' do
    let(:auto)     { true }
    let(:articles) { create_list(:ticket_article, 30, ticket:, body: 'Hello world.', content_type: 'text/plain') }

    it 'translates the older page and preserves an individual original override' do
      expect(page).to have_text('Hallo Welt.')
      expect(page).to have_no_text('Übersetzter Beitrag 6')

      find("#article-#{articles.first.id}").hover
      within "#article-#{articles.first.id}" do
        click_on 'Show original'
        expect(page).to have_text('Hello world.')
      end

      click_on 'Load 5 more'

      expect(page).to have_text('Übersetzter Beitrag 6')
      within "#article-#{articles.first.id}" do
        expect(page).to have_text('Hello world.')
        expect(page).to have_no_text('Hallo Welt.')
      end
    end
  end

  it 'translates the whole ticket and returns it to its originals' do
    open_translation_menu

    find('[data-test-id="translate-all-articles"]').click

    expect(page).to have_text('Hallo Welt.').and(have_text('Wie geht es dir?'))

    find('[data-test-id="translate-all-articles"]').click

    expect(page).to have_text('Hello world.').and(have_text('How are you?'))
  end

  context 'when the agent is outside the configured roles' do
    before do
      Setting.set('content_translation_ticket_article_auto_role_ids', [create(:role).id])

      refresh
      wait_for_gql('shared/entities/ticket/graphql/queries/ticket/articles.graphql')
    end

    it 'offers the target language without the switch' do
      open_translation_menu

      expect(page).to have_text('Target language')
      expect(page).to have_no_css('[data-test-id="translate-all-articles"]')
    end
  end
end
