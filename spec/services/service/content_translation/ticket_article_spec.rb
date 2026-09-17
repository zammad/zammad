# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Covers Service::ContentTranslation::Base and its AI backend through their first subclass.
RSpec.describe Service::ContentTranslation::TicketArticle, performs_jobs: true do
  let(:target_locale) { 'de-de' }
  let(:content_type)  { 'text/html' }
  let(:body)          { '<p>Hello <strong>world</strong>.</p>' }
  let(:article)       { create(:ticket_article, body:, content_type:) }
  let(:llm_response)  { '<p>Hallo <strong>Welt</strong>.</p>' }

  # Every prompt pair the provider was asked with — the size doubles as the call count.
  let(:provider_calls) { [] }

  # Most examples are about what is translated rather than about deferring, so they ask for an
  # answer in place; the deferral itself has its own describe block.
  def translate(**args)
    described_class.execute(object: article, target_locale:, background: false, **args)
  end

  before do
    setup_ai_provider('zammad_ai')
    setup_content_translation

    allow_any_instance_of(AI::Provider::ZammadAI).to receive(:ask) do |_provider, **prompts|
      provider_calls << prompts
      llm_response
    end
  end

  it 'returns the translation of the article' do
    result = translate

    expect(result).to have_attributes(
      content:    llm_response,
      backend:    'ai',
      translated: true,
      fresh:      true,
    )
  end

  it 'returns the analytics run for the feedback widget' do
    expect(translate.analytics_run).to be_a(AI::Analytics::Run)
  end

  # Not to its ticket: that would freeze which ticket authorizes the run, and a merge moves the
  #   article to another one.
  it 'relates the analytics run to the article' do
    expect(translate.analytics_run.related_object).to eq(article)
  end

  it 'serves a second request from the stored translation' do
    translate

    expect(translate)
      .to have_attributes(content: llm_response, fresh: false)
  end

  context 'when the AI provider is not configured' do
    before { unset_ai_provider }

    it 'still serves a translation that is already stored' do
      setup_ai_provider('zammad_ai')
      translate
      unset_ai_provider

      expect(translate)
        .to have_attributes(content: llm_response, fresh: false)
    end

    it 'raises an error' do
      expect { translate }
        .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'AI provider is not configured.')
    end
  end

  describe 'honouring the feature toggles' do
    # A translation is stored first: a switched-off feature must not serve it either.
    before { translate }

    context 'when no translation service is configured' do
      before { Setting.set('content_translation_service', false) }

      it 'refuses although a translation is stored' do
        expect { translate }
          .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'No translation service is configured.')
      end

      it 'asks no provider' do
        expect { translate }
          .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError)
          .and not_change(provider_calls, :size)
      end

      it 'consults no store' do
        allow(Service::AI::Feature::Translate).to receive(:execute)

        suppress(Service::CheckFeatureEnabled::FeatureDisabledError) { translate }

        expect(Service::AI::Feature::Translate).not_to have_received(:execute)
      end
    end

    context 'when article translation is switched off' do
      before { Setting.set('content_translation_ticket_article', false) }

      it 'refuses although a translation is stored' do
        expect { translate }
          .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'Ticket article translation is not enabled.')
      end

      it 'asks no provider' do
        expect { translate }
          .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError)
          .and not_change(provider_calls, :size)
      end

      it 'consults no store' do
        allow(Service::AI::Feature::Translate).to receive(:execute)

        suppress(Service::CheckFeatureEnabled::FeatureDisabledError) { translate }

        expect(Service::AI::Feature::Translate).not_to have_received(:execute)
      end
    end
  end

  describe '.stored_translations' do
    let(:german)        { Locale.find_by(locale: 'de-de') }
    let(:html_article)  { create(:ticket_article, body: '<p>Hello</p>', content_type: 'text/html') }
    let(:plain_article) { create(:ticket_article, body: 'Hello', content_type: 'text/plain') }
    let(:other_article) { create(:ticket_article, body: '<p>Other</p>', content_type: 'text/html') }
    let(:articles)      { [html_article, plain_article, other_article] }

    def store(article, content, locale: german, backend: 'ai')
      html = article.content_type.match?(%r{html}i)
      AI::StoredResult.create!(
        content:,
        metadata: { 'backend' => backend },
        version:  Service::AI::Feature::Translate.lookup_version({ html:, body: article.body, backend: }, locale),
        **Service::AI::Feature::Translate.lookup_attributes({ object: article }, locale)
      )
    end

    before do
      store(html_article, '<p>Hallo</p>')
      store(plain_article, 'Hallo')
    end

    it 'finds the translations of the given articles' do
      expect(described_class.stored_translations(articles, 'de-de').map(&:related_object_id))
        .to contain_exactly(html_article.id, plain_article.id)
    end

    it 'leaves out a translation of former content' do
      html_article.update!(body: '<p>Hello again</p>')

      expect(described_class.stored_translations(articles, 'de-de').map(&:related_object_id))
        .to eq([plain_article.id])
    end

    it 'leaves out translations into other locales' do
      store(other_article, '<p>Autre</p>', locale: Locale.find_by(locale: 'fr-fr'))

      expect(described_class.stored_translations(articles, 'de-de').map(&:related_object_id))
        .not_to include(other_article.id)
    end

    it 'leaves out a translation of another backend' do
      store(other_article, '<p>Hallo</p>', backend: 'libre_translate')

      expect(described_class.stored_translations(articles, 'de-de').map(&:related_object_id))
        .not_to include(other_article.id)
    end

    it 'finds what the configured backend stored' do
      allow(Service::ContentTranslation::Backend)
        .to receive(:configured).and_return(Service::ContentTranslation::Backend::LibreTranslate)
      store(other_article, '<p>Hallo</p>', backend: 'libre_translate')

      expect(described_class.stored_translations(articles, 'de-de').map(&:related_object_id))
        .to eq([other_article.id])
    end

    it 'leaves the content out' do
      expect { described_class.stored_translations(articles, 'de-de').first.content }
        .to raise_error(ActiveModel::MissingAttributeError)
    end

    it 'finds nothing for an unknown locale' do
      expect(described_class.stored_translations(articles, 'xx-xx')).to be_empty
    end
  end

  describe '.for_display' do
    let(:cid)     { "#{SecureRandom.uuid}@zammad.example.com" }
    let(:body)    { "<p>Hello</p><img src=\"cid:#{cid}\">" }
    let(:article) { create(:ticket_article, body:, content_type:) }
    let(:translation) do
      Service::ContentTranslation::Base::Result[content: "<p>Hallo</p><img src=\"cid:#{cid}\">", backend: 'ai', translated: true, fresh: true, analytics_run: nil]
    end

    before do
      create(:store, object: 'Ticket::Article', o_id: article.id, data: 'fake', filename: 'inline.jpg',
                     preferences: { 'Content-Type' => 'image/jpeg', 'Content-ID' => "<#{cid}>", 'Content-Disposition' => 'inline' })
    end

    it 'resolves inline image references like the display body of the article' do
      expect(described_class.for_display(article, translation)[:content])
        .to eq("<p>Hallo</p><img src=\"/api/v1/ticket_attachment/#{article.ticket_id}/#{article.id}/#{article.attachments.first.id}?view=inline\">")
    end

    it 'leaves the article untouched' do
      expect { described_class.for_display(article, translation) }
        .not_to change { article.reload.body }
    end

    it 'carries the producer and the translated flag' do
      expect(described_class.for_display(article, translation))
        .to include(backend: 'ai', translated: true)
    end

    it 'accepts the hash a background job publishes' do
      expect(described_class.for_display(article, { 'content' => '<p>Hallo</p>', 'backend' => 'deepl', 'translated' => true }))
        .to eq(content: '<p>Hallo</p>', backend: 'deepl', translated: true)
    end

    it 'keeps a missing translation missing, so the client sees no empty one' do
      expect(described_class.for_display(article, nil)).to be_nil
    end

    context 'with a plain text article' do
      let(:content_type) { 'text/plain' }
      let(:body)         { "Hello cid:#{cid}" }

      it 'returns the content as it is' do
        expect(described_class.for_display(article, translation)[:content]).to eq(translation.content)
      end
    end
  end

  describe 'resolving the configured translation service' do
    # The config validation refuses such a service; a backend removed later leaves the same state
    # behind, which is exactly the one that must not fall back to another service.
    context 'with an unknown service' do
      before { Setting.set('content_translation_service_config', { 'provider' => 'nope' }, validate: false) }

      it 'rejects instead of falling back' do
        expect { translate }
          .to raise_error(described_class::UnknownBackendError, 'The configured translation service is not available.')
          .and not_change(provider_calls, :size)
      end
    end

    context 'with a blank service' do
      before { Setting.set('content_translation_service_config', {}) }

      it 'rejects instead of falling back' do
        expect { translate }
          .to raise_error(described_class::UnknownBackendError)
          .and not_change(provider_calls, :size)
      end
    end

    context 'with a key that names something else in the namespace' do
      before { Setting.set('content_translation_service_config', { 'provider' => 'base' }, validate: false) }

      it 'rejects it' do
        expect { translate }.to raise_error(described_class::UnknownBackendError)
      end
    end

    context 'with another service configured' do
      let(:echo_backend) do
        Class.new(Service::ContentTranslation::Backend::Base) do
          def self.backend_name = 'echo'

          def initialize(content:, **) = @content = content # rubocop:disable Lint/MissingSuper

          def execute
            { content: "echo: #{@content}", backend: self.class.backend_name, fresh: true, analytics_run: nil }
          end
        end
      end

      before do
        stub_const('Service::ContentTranslation::Backend::Echo', echo_backend)
        Setting.set('content_translation_service_config', { 'provider' => 'echo' })
      end

      it 'is the one that answers' do
        expect(translate).to have_attributes(content: "echo: #{body}", backend: 'echo', translated: true)
      end

      it 'asks no AI provider' do
        translate

        expect(provider_calls).to be_empty
      end
    end
  end

  # The backend has its own spec; what is covered here is that the service resolves it, hands it the
  # article and answers with what it returns.
  describe 'with LibreTranslate configured' do
    let(:url)                { 'https://translate.example.com' }
    let(:endpoint)           { "#{url}/translate" }
    let(:languages_endpoint) { "#{url}/languages" }
    let(:languages)          { %w[en de] }
    let(:response)           { '<p>Hallo <strong>Welt</strong>.</p>' }

    before do
      stub_request(:get, languages_endpoint)
        .to_return(status: 200, body: languages.map { |code| { code: } }.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, endpoint)
        .to_return(status: 200, body: { translatedText: response }.to_json, headers: { 'Content-Type' => 'application/json' })

      # Without the validation: its connection test asks the instance to translate, which would
      # count towards the requests the examples below expect.
      Setting.set('content_translation_service_config', { 'provider' => 'libre_translate', 'url' => url }, validate: false)
    end

    it 'answers with its translation' do
      expect(translate)
        .to have_attributes(content: response, backend: 'libre_translate', translated: true, fresh: true)
    end

    it 'asks no AI provider' do
      translate

      expect(provider_calls).to be_empty
    end

    # One HTTP round trip is not worth a job and a subscription, so the backend does not defer.
    it 'answers in place although the caller could be answered later' do
      expect { described_class.execute(object: article, target_locale:) }
        .not_to have_enqueued_job(ContentTranslationJob)
    end

    it 'serves a second request without asking the instance again' do
      2.times { translate }

      expect(WebMock).to have_requested(:post, endpoint).once
    end

    describe 'when nothing usable comes back' do
      before { stub_request(:post, endpoint).to_return(status: 200, body: { translatedText: '' }.to_json, headers: { 'Content-Type' => 'application/json' }) }

      it 'answers with the untranslated article instead of with nothing' do
        expect(translate).to have_attributes(content: body, backend: nil, translated: false)
      end
    end

    # The service adds nothing to a failure of its backend: what the caller has to tell the
    # outcomes apart by is the class the backend raised.
    describe 'when the instance refuses the request' do
      before { stub_request(:post, endpoint).to_return(status: 403, body: { error: 'Invalid API key' }.to_json) }

      it 'surfaces the outcome unchanged' do
        expect { translate }.to raise_error(Service::ContentTranslation::Backend::Base::InvalidCredentialsError)
      end

      it 'stores nothing' do
        expect { suppress(Service::ContentTranslation::Backend::Base::Error) { translate } }
          .not_to change(AI::StoredResult, :count)
      end
    end

    describe 'with a target language the instance does not serve' do
      let(:languages) { %w[en fr] }

      it 'fails rather than answering with untranslated content' do
        expect { translate }.to raise_error(Service::ContentTranslation::Backend::Base::UnsupportedLanguageError)
      end

      it 'stores nothing' do
        expect { suppress(Service::ContentTranslation::Backend::Base::Error) { translate } }
          .not_to change(AI::StoredResult, :count)
      end

      # The service answers an article that is already in the target language before any backend is
      # asked, so an unsupported language must not start failing what was never translated.
      it 'still answers an article that is already in the target language' do
        article.update!(detected_language: 'de')

        expect(translate).to have_attributes(content: body, translated: false)
      end
    end
  end

  describe 'with DeepL configured' do
    let(:endpoint) { 'https://api-free.deepl.com/v2/translate' }
    let(:response) { '<p>Hallo <strong>Welt</strong>.</p>' }

    before do
      stub_request(:post, endpoint)
        .to_return(status: 200, body: { translations: [{ text: response }] }.to_json, headers: { 'Content-Type' => 'application/json' })

      # Without the validation: its connection test asks DeepL to translate, which would count
      # towards the requests the examples below expect.
      Setting.set('content_translation_service_config', { 'provider' => 'deepl', 'api_key' => 'secret-key', 'tier' => 'free' }, validate: false)
    end

    it 'answers with its translation' do
      expect(translate)
        .to have_attributes(content: response, backend: 'deepl', translated: true, fresh: true)
    end

    it 'asks no AI provider' do
      translate

      expect(provider_calls).to be_empty
    end

    # One HTTP round trip is not worth a job and a subscription, so the backend does not defer.
    it 'answers in place although the caller could be answered later' do
      expect { described_class.execute(object: article, target_locale:) }
        .not_to have_enqueued_job(ContentTranslationJob)
    end

    it 'serves a second request without asking DeepL again' do
      2.times { translate }

      expect(WebMock).to have_requested(:post, endpoint).once
    end

    # The service adds nothing to a failure of its backend: what the caller has to tell the outcomes
    # apart by is the class the backend raised.
    describe 'when DeepL refuses the request' do
      before { stub_request(:post, endpoint).to_return(status: 403, body: { message: 'Authorization failed' }.to_json) }

      it 'surfaces the outcome unchanged' do
        expect { translate }.to raise_error(Service::ContentTranslation::Backend::Base::InvalidCredentialsError)
      end

      it 'stores nothing' do
        expect { suppress(Service::ContentTranslation::Backend::Base::Error) { translate } }
          .not_to change(AI::StoredResult, :count)
      end
    end

    describe 'with a target language DeepL does not serve' do
      let(:target_locale) { 'rw' }

      it 'fails rather than answering with untranslated content' do
        expect { translate }.to raise_error(Service::ContentTranslation::Backend::Base::UnsupportedLanguageError)
      end

      it 'sends no content' do
        suppress(Service::ContentTranslation::Backend::Base::Error) { translate }

        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end

    # The two services key their rows apart, so the one that is configured now has to translate
    # again rather than serve what the other one left behind.
    it 'does not serve what LibreTranslate stored for the same article' do
      Service::ContentTranslation::StoredTranslation.save(
        object: article, locale: Locale.find_by(locale: target_locale), content: body, html: true,
        backend: 'libre_translate', translation: '<p>Von der Instanz.</p>'
      )

      expect(translate).to have_attributes(content: response, backend: 'deepl', fresh: true)
    end
  end

  # Showing that switching the service does not serve the previous one's translation needs a second
  # backend that uses the same store, which the echo double above deliberately does not - it answers
  # without storing anything.
  describe 'switching the configured translation service' do
    # What a backend without an AI feature behind it does: read the store, or translate and write it.
    let(:mirror_backend) do
      Class.new(Service::ContentTranslation::Backend::Base) do
        def self.backend_name = 'mirror'

        def initialize(object:, content:, html:, locale:, persistence_strategy: :stored_or_request, **) # rubocop:disable Lint/MissingSuper
          @content              = content
          @persistence_strategy = persistence_strategy
          @key                  = { object:, locale:, content:, html:, backend: self.class.backend_name }
        end

        def execute
          stored = Service::ContentTranslation::StoredTranslation.find(**@key) if @persistence_strategy != :request_only

          return { content: stored.content, backend: stored.metadata['backend'], fresh: false, analytics_run: nil } if stored
          return if @persistence_strategy == :stored_only

          row = Service::ContentTranslation::StoredTranslation.save(**@key, translation: "mirror: #{@content}")

          { content: row.content, backend: self.class.backend_name, fresh: true, analytics_run: nil }
        end
      end
    end

    before { stub_const('Service::ContentTranslation::Backend::Mirror', mirror_backend) }

    def configure(provider)
      Setting.set('content_translation_service_config', { 'provider' => provider })
    end

    it 'translates again instead of serving what the AI backend stored' do
      translate
      configure('mirror')

      expect(translate).to have_attributes(content: "mirror: #{body}", backend: 'mirror', fresh: true)
    end

    it 'asks the AI provider again instead of serving what the other backend stored' do
      configure('mirror')
      translate
      configure('ai')

      expect { translate }.to change(provider_calls, :size).by(1)
    end

    it 'serves its own stored translation while it stays configured' do
      configure('mirror')
      translate

      expect(translate).to have_attributes(content: "mirror: #{body}", fresh: false)
    end

    it 'keeps one stored translation per article and locale' do
      translate
      configure('mirror')

      expect { translate }.not_to change(AI::StoredResult, :count)
    end
  end

  context 'when the article has no content' do
    before { article.body = '' }

    it 'returns the content as untranslated' do
      expect(translate)
        .to have_attributes(content: '', translated: false)
    end

    it 'asks no provider' do
      translate

      expect(provider_calls).to be_empty
    end
  end

  context 'with a target locale that cannot be translated into' do
    it 'rejects an unknown locale without asking the provider' do
      expect { translate(target_locale: 'xx-xx') }
        .to raise_error(described_class::InvalidTargetLocaleError)
        .and not_change(provider_calls, :size)
    end

    it 'rejects an inactive locale without asking the provider' do
      Locale.find_by(locale: target_locale).update!(active: false)

      expect { translate }
        .to raise_error(described_class::InvalidTargetLocaleError)
        .and not_change(provider_calls, :size)
    end
  end

  context 'when the article language is already the target language' do
    let(:article) { create(:ticket_article, body:, content_type:, detected_language: 'de') }

    it 'returns the original content as untranslated' do
      expect(translate)
        .to have_attributes(content: body, translated: false, backend: nil)
    end

    it 'asks no provider' do
      translate

      expect(provider_calls).to be_empty
    end

    it 'translates into another language' do
      expect(translate(target_locale: 'en-us'))
        .to have_attributes(translated: true)
    end
  end

  context 'when the detected language has locales that differ by script' do
    let(:article) { create(:ticket_article, body:, content_type:, detected_language: 'zh') }

    it 'translates instead of skipping' do
      expect(translate(target_locale: 'zh-tw'))
        .to have_attributes(translated: true)
    end
  end

  context 'with a given source language' do
    it 'skips without the article being detected' do
      expect(translate(source_language: 'de'))
        .to have_attributes(content: body, translated: false)
    end

    it 'accepts a locale code as well' do
      expect(translate(source_language: 'de-de'))
        .to have_attributes(translated: false)
    end

    it 'overrules the detected language of the article' do
      article.update!(detected_language: 'de')

      expect(translate(source_language: 'en'))
        .to have_attributes(translated: true)
    end

    it 'skips for a script variant when the locale matches exactly' do
      expect(translate(target_locale: 'zh-tw', source_language: 'zh-tw'))
        .to have_attributes(translated: false)
    end

    it 'translates a script variant into another script' do
      expect(translate(target_locale: 'zh-tw', source_language: 'zh-cn'))
        .to have_attributes(translated: true)
    end
  end

  context 'when the detected language names a script variant' do
    let(:article) { create(:ticket_article, body:, content_type:, detected_language: 'zh-TW') }

    it 'skips a request for the same locale' do
      expect(translate(target_locale: 'zh-tw'))
        .to have_attributes(translated: false)
    end

    it 'translates a request for the other script' do
      expect(translate(target_locale: 'zh-cn'))
        .to have_attributes(translated: true)
    end
  end

  context 'when the detected language names no script' do
    let(:article) { create(:ticket_article, body:, content_type:, detected_language: 'sr') }

    it 'skips a request for the script CLDR considers likely' do
      expect(translate(target_locale: 'sr-cyrl-rs'))
        .to have_attributes(translated: false)
    end

    it 'translates a request for the other script' do
      expect(translate(target_locale: 'sr-latn-rs'))
        .to have_attributes(translated: true)
    end
  end

  context 'with a forced translation' do
    let(:article) { create(:ticket_article, body:, content_type:, detected_language: 'de') }

    it 'translates although the article is already in the target language' do
      expect(translate(force: true))
        .to have_attributes(content: llm_response, translated: true)
    end
  end

  context 'without a detected language' do
    it 'translates instead of skipping' do
      expect(translate).to have_attributes(translated: true)
    end
  end

  describe 'deferring to the background' do
    it 'translates in place when the caller cannot be answered later' do
      expect(described_class.execute(object: article, target_locale:, background: false))
        .to have_attributes(content: llm_response, translated: true)
    end

    it 'enqueues nothing when the caller cannot be answered later' do
      expect { described_class.execute(object: article, target_locale:, background: false) }
        .not_to have_enqueued_job(ContentTranslationJob)
    end

    it 'defers to a job when the backend is slow' do
      expect { described_class.execute(object: article, target_locale:) }
        .to have_enqueued_job(ContentTranslationJob).with(article, target_locale, service: 'Service::ContentTranslation::TicketArticle', regeneration_of: nil)
    end

    it 'returns nothing when it deferred' do
      expect(described_class.execute(object: article, target_locale:)).to be_nil
    end

    it 'asks no provider when it deferred' do
      described_class.execute(object: article, target_locale:)

      expect(provider_calls).to be_empty
    end

    context 'when a translation is stored' do
      before { described_class.execute(object: article, target_locale:, background: false) }

      it 'serves it instead of deferring' do
        expect { described_class.execute(object: article, target_locale:) }
          .not_to have_enqueued_job(ContentTranslationJob)
      end

      it 'returns it' do
        expect(described_class.execute(object: article, target_locale:))
          .to have_attributes(content: llm_response, fresh: false)
      end
    end

    context 'with a regeneration' do
      let(:regeneration_of) { create(:ai_analytics_run) }

      before { translate }

      it 'carries it into the job although a translation is stored' do
        expect { described_class.execute(object: article, target_locale:, regeneration_of:) }
          .to have_enqueued_job(ContentTranslationJob)
          .with(article, target_locale, service: 'Service::ContentTranslation::TicketArticle', regeneration_of:)
      end
    end

    context 'with a backend that answers fast' do
      before do
        allow(Service::ContentTranslation::Backend::AI).to receive(:background?).and_return(false)
      end

      it 'translates in place although the caller could be answered later' do
        expect(described_class.execute(object: article, target_locale:))
          .to have_attributes(content: llm_response, translated: true)
      end

      it 'enqueues no job' do
        expect { described_class.execute(object: article, target_locale:) }
          .not_to have_enqueued_job(ContentTranslationJob)
      end
    end
  end

  describe 'passing arguments to the backend' do
    it 'passes the persistence strategy through' do
      expect(translate(persistence_strategy: :stored_only)).to be_nil
    end

    it 'asks the provider with a request-only strategy although a translation is stored' do
      translate

      expect { translate(persistence_strategy: :request_only) }
        .to change(provider_calls, :size).by(1)
    end

    it 'asks no provider with a stored-only strategy' do
      translate(persistence_strategy: :stored_only)

      expect(provider_calls).to be_empty
    end

    it 'marks an HTML article as HTML' do
      allow(Service::AI::Feature::Translate).to receive(:execute)

      translate

      expect(Service::AI::Feature::Translate)
        .to have_received(:execute).with(hash_including(context_data: hash_including(html: true))).at_least(:once)
    end

    context 'with a plain text article' do
      let(:content_type) { 'text/plain' }

      it 'marks the article as plain text' do
        allow(Service::AI::Feature::Translate).to receive(:execute)

        translate

        expect(Service::AI::Feature::Translate)
          .to have_received(:execute).with(hash_including(context_data: hash_including(html: false))).at_least(:once)
      end
    end

    it 'passes the regeneration through' do
      regeneration_of = create(:ai_analytics_run)

      allow(Service::AI::Feature::Translate).to receive(:execute)

      translate(regeneration_of:)

      expect(Service::AI::Feature::Translate)
        .to have_received(:execute).with(hash_including(regeneration_of:)).at_least(:once)
    end
  end
end
