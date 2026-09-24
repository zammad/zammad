# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::TicketArticle::TranslateMany, performs_jobs: true do
  subject(:service) { described_class.with_current_user(agent) }

  let(:agent)         { create(:agent, groups: [ticket.group]) }
  let(:ticket)        { create(:ticket) }
  let(:articles)      { create_list(:ticket_article, 2, ticket:, body: 'Hello world.', content_type: 'text/plain') }
  let(:target_locale) { 'de-de' }

  let(:translate) { service.execute(articles:, target_locale:, generate_missing: true) }

  before do
    setup_ai_provider('zammad_ai')
    setup_content_translation
    Setting.set('content_translation_ticket_article_auto', true)

    allow_any_instance_of(AI::Provider::ZammadAI).to receive(:ask).and_return('Hallo Welt.')
  end

  it 'enqueues and identifies pending translations', :aggregate_failures do
    expect { translate }.to have_enqueued_job(ContentTranslationJob).exactly(articles.count).times
    expect(translate).to match_array(articles.map { |article| { article:, translation: nil } })
  end

  %w[deepl libre_translate].each do |provider|
    context "with #{provider} configured" do
      let(:endpoint) { provider == 'deepl' ? 'https://api-free.deepl.com/v2/translate' : 'https://translate.example.com/translate' }
      let(:response) { provider == 'deepl' ? { translations: [{ text: 'Hallo Welt.' }] } : { translatedText: 'Hallo Welt.' } }

      before do
        Setting.set('content_translation_service_config', { provider:, api_key: 'test', tier: 'free', url: 'https://translate.example.com' }, validate: false)
        stub_request(:get, 'https://translate.example.com/languages')
          .to_return_json(body: [{ code: 'en' }, { code: 'de' }])
        stub_request(:post, endpoint).to_return_json(body: response)
        allow(Gql::Subscriptions::Ticket::Article::TranslationUpdates).to receive(:trigger_for)
      end

      it 'generates in jobs, publishes results and reuses them on the next request', :aggregate_failures do
        expect { translate }.to have_enqueued_job(ContentTranslationJob).exactly(articles.count).times
        expect(translate).to match_array(articles.map { |article| { article:, translation: nil } })
        expect(WebMock).not_to have_requested(:post, endpoint)

        perform_enqueued_jobs(only: ContentTranslationJob)

        expect(WebMock).to have_requested(:post, endpoint).twice
        expect(Gql::Subscriptions::Ticket::Article::TranslationUpdates)
          .to have_received(:trigger_for).with(
            anything, target_locale,
            { translation: { content: 'Hallo Welt.', backend: provider, translated: true }, ai_analytics_run_id: be_present }
          ).twice
        expect { service.execute(articles:, target_locale:, generate_missing: true) }.not_to have_enqueued_job(ContentTranslationJob)
        expect(service.execute(articles:, target_locale:, generate_missing: true).pluck(:translation))
          .to all(have_attributes(content: 'Hallo Welt.', translated: true))
      end
    end
  end

  context 'with a stored translation' do
    before do
      Service::ContentTranslation::TicketArticle
        .execute(object: articles.first, target_locale:, background: false)
    end

    it 'returns the stored translation and enqueues only the missing one', :aggregate_failures do
      expect { translate }.to have_enqueued_job(ContentTranslationJob).once
      expect(translate).to contain_exactly(
        hash_including(article: articles.first, translation: have_attributes(translated: true)),
        { article: articles.last, translation: nil }
      )
    end
  end

  context 'with an article already in the target language' do
    let(:articles) { [create(:ticket_article, ticket:, body: 'Hallo Welt.', content_type: 'text/plain', detected_language: 'de')] }

    it 'returns its original content without enqueuing a translation', :aggregate_failures do
      expect { translate }.not_to have_enqueued_job(ContentTranslationJob)
      expect(translate).to contain_exactly(
        hash_including(translation: have_attributes(content: 'Hallo Welt.', translated: false))
      )
    end
  end

  context 'with system and delivery notices' do
    let(:articles) do
      [
        create(:ticket_article, ticket:, sender_name: 'System', type_name: 'email'),
        create(:ticket_article, ticket:, sender_name: 'System', type_name: 'note', preferences: { delivery_message: true }),
        create(:ticket_article, ticket:, sender_name: 'System', type_name: 'note'),
      ]
    end

    it 'translates only the ordinary note', :aggregate_failures do
      expect(translate).to eq([{ article: articles.first }, { article: articles.second }, { article: articles.last, translation: nil }])
      expect(ContentTranslationJob).to have_been_enqueued.once
    end
  end

  it 'reuses results when overlapping requests are processed', :aggregate_failures do
    perform_enqueued_jobs(only: ContentTranslationJob) { translate }

    expect { service.execute(articles:, target_locale:, generate_missing: true) }.not_to have_enqueued_job(ContentTranslationJob)
    expect(service.execute(articles:, target_locale:, generate_missing: true).pluck(:translation)).to all(have_attributes(translated: true))
  end

  context 'when the user may not translate automatically' do
    before { Setting.set('content_translation_ticket_article_auto_role_ids', [create(:role).id]) }

    it 'refuses generation but allows lookup without invoking the translation service', :aggregate_failures do
      allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_call_original
      expect(service.execute(articles:, target_locale:)).to eq(articles.map { |article| { article: } })
      expect(Service::ContentTranslation::TicketArticle).not_to have_received(:execute)
      expect { translate }
        .to raise_error(Exceptions::Forbidden, 'Automatic translation of ticket articles is not available for you.')
    end
  end

  context 'when article translation is disabled' do
    before { Setting.set('content_translation_ticket_article', false) }

    it 'also refuses lookup-only requests' do
      expect { service.execute(articles:, target_locale:) }.to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError)
    end
  end

  context 'without a current user' do
    it 'refuses the request' do
      expect { described_class.execute(articles:, target_locale:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
