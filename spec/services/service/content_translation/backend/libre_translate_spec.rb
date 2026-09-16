# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::Backend::LibreTranslate do
  let(:url)                { 'https://translate.example.com' }
  let(:endpoint)           { "#{url}/translate" }
  let(:languages_endpoint) { "#{url}/languages" }
  let(:languages)          { %w[en de] }
  let(:api_key)            { nil }
  let(:locale)             { Locale.find_by(locale: 'de-de') }
  let(:html)               { true }
  let(:content)            { '<p>Hello <strong>world</strong>.</p>' }
  let(:translation)        { '<p>Hallo <strong>Welt</strong>.</p>' }
  let(:article)            { create(:ticket_article, body: content, content_type: html ? 'text/html' : 'text/plain') }

  # What the instance answers, in the shape UserAgent parses as JSON.
  def answer(text, status: 200)
    { status:, body: { translatedText: text }.to_json, headers: { 'Content-Type' => 'application/json' } }
  end

  def stub_translate(text)
    stub_request(:post, endpoint).to_return(**answer(text))
  end

  def stub_languages(codes)
    stub_request(:get, languages_endpoint)
      .to_return(status: 200, body: codes.map { |code| { code: } }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_refusal(status, error)
    stub_request(:post, endpoint)
      .to_return(status:, body: { error: }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def translate(**)
    described_class.execute(object: article, content:, html:, locale:, **)
  end

  before do
    # Without the validation, because saving the config runs the connection test - which would ask
    # the instance and fill the language cache before the examples below have said anything.
    Setting.set('content_translation_service_config', { 'provider' => 'libre_translate', 'url' => url, 'api_key' => api_key }.compact, validate: false)

    stub_languages(languages)
    stub_translate(translation)
  end

  it 'returns the translation' do
    expect(translate).to include(content: translation, backend: 'libre_translate', fresh: true)
  end

  it 'records no analytics run' do
    expect(translate[:analytics_run]).to be_nil
  end

  it 'names the target language without its region' do
    translate

    expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target' => 'de'))
  end

  describe 'preserving the structure of the content' do
    it 'asks for the HTML format' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('format' => 'html', 'q' => content))
    end

    context 'with plain text content' do
      let(:html)        { false }
      let(:content)     { 'Hello world.' }
      let(:translation) { 'Hallo Welt.' }

      it 'asks for the text format' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('format' => 'text', 'q' => content))
      end

      it 'returns the translation' do
        expect(translate).to include(content: translation, fresh: true)
      end
    end

    context 'when the instance does not accept HTML' do
      before do
        stub_request(:post, endpoint)
          .with(body: hash_including('format' => 'html'))
          .to_return(status: 400, body: { error: 'html format is not supported' }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, endpoint)
          .with(body: hash_including('format' => 'text'))
          .to_return(**answer("Hallo\nWelt."))
      end

      it 'sends the content again without its markup' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('format' => 'text', 'q' => 'Hello world.'))
      end

      # The answer is plain text, but it replaces the body of an HTML article - so its line breaks
      # have to survive as markup.
      it 'returns the plain text answer as HTML' do
        expect(translate).to include(content: 'Hallo<br>Welt.', fresh: true)
      end
    end
  end

  describe 'when no translation comes out of the request' do
    shared_examples 'answering with nothing' do
      it 'returns nothing' do
        expect(translate).to be_nil
      end

      it 'stores nothing' do
        expect { translate }.not_to change(AI::StoredResult, :count)
      end
    end

    context 'when the instance answers with an empty translation' do
      before { stub_translate('') }

      include_examples 'answering with nothing'
    end

    context 'when sanitizing removes everything' do
      before { stub_translate('<script>alert(1)</script>') }

      include_examples 'answering with nothing'
    end

    # Storing it would serve the sanitizer's own English message as the translation of this content.
    context 'when the sanitizer gives up on the answer' do
      before { allow(HtmlSanitizer).to receive(:strict).and_return(HtmlSanitizer::UNPROCESSABLE_HTML_MSG) }

      include_examples 'answering with nothing'
    end
  end

  describe 'when the instance refuses the request' do
    before { stub_refusal(403, 'Invalid API key') }

    it 'raises the outcome it maps onto' do
      expect { translate }.to raise_error(described_class::InvalidCredentialsError)
    end

    # Only a refused HTML format is retried, and that one is answered before the outcome is picked.
    it 'makes no second request' do
      suppress(described_class::Error) { translate }

      expect(WebMock).to have_requested(:post, endpoint).once
    end

    it 'stores nothing' do
      expect { suppress(described_class::Error) { translate } }.not_to change(AI::StoredResult, :count)
    end
  end

  # Which failure the client maps onto which of its own errors is its spec's matter; this one
  # covers that none of them reaches a caller unmapped.
  describe 'mapping a failure onto one of the outcomes' do
    it 'maps a refusal onto its outcome' do
      stub_refusal(429, 'Slowdown: 60 per 1 minute')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    it 'maps a failing language listing onto an outcome too' do
      stub_request(:get, languages_endpoint).to_return(status: 503, body: 'Service Unavailable')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    # Every request has to come out as one of the outcomes rather than escaping untyped.
    it 'maps an answer none of the outcomes describes onto unreachable' do
      stub_refusal(400, 'Invalid request: missing q parameter')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    it 'maps a language the instance has no model for onto unsupported language' do
      stub_refusal(400, 'de is not supported')

      expect { translate }.to raise_error(described_class::UnsupportedLanguageError)
    end

    # Shares its wording with the refused HTML format, which #translate answers before the mapping.
    it 'does not take that for a refused HTML format and retry it as text' do
      stub_refusal(400, 'de is not supported')

      suppress(described_class::Error) { translate }

      expect(WebMock).to have_requested(:post, endpoint).once
    end
  end

  describe 'the target language' do
    it 'asks the instance which languages it serves' do
      translate

      expect(WebMock).to have_requested(:get, languages_endpoint)
    end

    context 'when the instance does not serve it' do
      let(:languages) { %w[en fr] }

      it 'raises' do
        expect { translate }.to raise_error(described_class::UnsupportedLanguageError, %r{de-de})
      end

      # The point of asking beforehand: an unsupported target must fail rather than come back as
      # content that was never translated.
      it 'sends no content' do
        suppress(described_class::Error) { translate }

        expect(WebMock).not_to have_requested(:post, endpoint)
      end

      it 'stores nothing' do
        expect { suppress(described_class::Error) { translate } }.not_to change(AI::StoredResult, :count)
      end

      it 'still serves what is stored' do
        Service::ContentTranslation::StoredTranslation
          .save(object: article, locale:, content:, html:, backend: 'libre_translate', translation:)

        expect(translate).to include(content: translation, fresh: false)
      end
    end

    # LibreTranslate knows a few of Zammad's locales under a code of its own rather than under
    # their primary subtag.
    context 'with a locale LibreTranslate spells differently' do
      let(:locale)    { Locale.find_by(locale: 'zh-tw') }
      let(:languages) { %w[en zh zt] }

      it 'asks for Traditional Chinese rather than for Simplified' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target' => 'zt'))
      end

      # Serving Simplified content for a Traditional target would be the wrong writing system.
      context 'when the instance serves only the other script' do
        let(:languages) { %w[en zh] }

        it 'raises' do
          expect { translate }.to raise_error(described_class::UnsupportedLanguageError)
        end
      end
    end

    context 'with a locale whose region the instance serves' do
      let(:locale)    { Locale.find_by(locale: 'pt-br') }
      let(:languages) { %w[en pb pt] }

      it 'asks for the regional code' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target' => 'pb'))
      end
    end

    # Only the region differs there, so the language itself is still the right answer.
    context 'with a locale whose region the instance does not serve' do
      let(:locale)    { Locale.find_by(locale: 'pt-br') }
      let(:languages) { %w[en pt] }

      it 'falls back on the language' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target' => 'pt'))
      end
    end
  end

  describe 'the store' do
    it 'serves a second translation from it' do
      translate

      expect(translate).to include(content: translation, backend: 'libre_translate', fresh: false)
    end

    it 'makes no second request' do
      2.times { translate }

      expect(WebMock).to have_requested(:post, endpoint).once
    end

    it 'answers with its own translation when the store lost a race' do
      allow(Service::ContentTranslation::StoredTranslation).to receive(:save).and_return(nil)

      expect(translate).to include(content: translation, fresh: true)
    end

    it 'does not serve what another service stored' do
      Service::ContentTranslation::StoredTranslation
        .save(object: article, locale:, content:, html:, backend: 'ai', translation: '<p>Von der KI.</p>')

      expect(translate).to include(content: translation, fresh: true)
    end

    context 'with a stored-only strategy' do
      it 'returns nothing while nothing is stored' do
        expect(translate(persistence_strategy: :stored_only)).to be_nil
      end

      it 'makes no request' do
        translate(persistence_strategy: :stored_only)

        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end

    it 'translates again with a request-only strategy although a translation is stored' do
      translate
      translate(persistence_strategy: :request_only)

      expect(WebMock).to have_requested(:post, endpoint).twice
    end

    it 'translates again for a regeneration although a translation is stored' do
      translate
      translate(regeneration_of: create(:ai_analytics_run))

      expect(WebMock).to have_requested(:post, endpoint).twice
    end
  end

  describe 'the connection test' do
    let(:config) { { url:, api_key: }.compact }

    def ping
      described_class.ping!(config)
    end

    it 'passes for an instance that answers' do
      expect { ping }.not_to raise_error
    end

    # A cached list would report a server that went down since the last translation as reachable.
    it 'asks the instance although the language list is cached' do
      described_class.client(config).languages
      ping

      expect(WebMock).to have_requested(:get, languages_endpoint).twice
    end

    it 'maps a refused listing onto its outcome' do
      stub_request(:get, languages_endpoint).to_return(status: 502)

      expect { ping }.to raise_error(described_class::UnreachableError)
    end

    it 'maps a URL no request can be built from onto its outcome' do
      expect { described_class.ping!({ url: 'translate.example.com' }) }
        .to raise_error(described_class::UnreachableError)
    end

    it 'asks for a language the instance named' do
      ping

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target' => languages.first))
    end

    # The language listing answers without a key, so only a translation proves the instance takes
    # the configuration - including an instance that demands a key none is configured for.
    it 'sends no key while none is configured' do
      ping

      expect(WebMock).to have_requested(:post, endpoint).with { |request| !JSON.parse(request.body).key?('api_key') }
    end

    # The language listing is exempt from the key check and may answer while the translation
    # endpoint does not, so only this request reports the instance as unusable.
    it 'maps a translation endpoint that does not answer onto its outcome' do
      stub_refusal(502, 'Bad Gateway')

      expect { ping }.to raise_error(described_class::UnreachableError)
    end

    it 'maps an instance that demands a key onto its outcome' do
      stub_refusal(403, 'Please contact the server operator to obtain an API key')

      expect { ping }.to raise_error(described_class::InvalidCredentialsError)
    end

    context 'with an API key configured' do
      let(:api_key) { 'secret-key' }

      it 'has the instance accept it' do
        ping

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('api_key' => api_key))
      end

      it 'maps a rejected key onto its outcome' do
        stub_refusal(403, 'Invalid API key')

        expect { ping }.to raise_error(described_class::InvalidCredentialsError)
      end

      # Refusing the configuration over the language pair the probe chose would leave the admin
      # with nothing to correct.
      it 'accepts a refusal that says nothing about the key' do
        stub_refusal(429, 'Slowdown: too many requests')

        expect { ping }.not_to raise_error
      end
    end
  end
end
