# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::Backend::DeepL do
  let(:endpoint)    { 'https://api-free.deepl.com/v2/translate' }
  let(:api_key)     { 'secret-key' }
  let(:tier)        { 'free' }
  let(:locale)      { Locale.find_by(locale: 'de-de') }
  let(:html)        { true }
  let(:content)     { '<p>Hello <strong>world</strong>.</p>' }
  let(:translation) { '<p>Hallo <strong>Welt</strong>.</p>' }
  let(:article)     { create(:ticket_article, body: content, content_type: html ? 'text/html' : 'text/plain') }

  # What DeepL answers, in the shape UserAgent parses as JSON.
  def stub_translate(text)
    stub_request(:post, endpoint)
      .to_return(status: 200, body: { translations: [{ detected_source_language: 'EN', text: }] }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_refusal(status, message)
    stub_request(:post, endpoint)
      .to_return(status:, body: { message: }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def translate(**)
    described_class.execute(object: article, content:, html:, locale:, **)
  end

  before do
    # Without the validation: its connection test asks DeepL to translate, which would count
    # towards the requests the examples below expect.
    Setting.set('content_translation_service_config', { 'provider' => 'deepl', 'api_key' => api_key, 'tier' => tier }, validate: false)

    stub_translate(translation)
  end

  it 'returns the translation' do
    expect(translate).to include(content: translation, backend: 'deepl', fresh: true)
  end

  describe 'the analytics run' do
    it 'records one for the article and the target locale' do
      expect(translate[:analytics_run])
        .to have_attributes(identifier: 'translate', related_object: article, locale:)
    end

    it 'names the service that produced the translation' do
      expect(translate[:analytics_run].ai_service_name).to eq('deepl')
    end

    # The AI agent satisfaction figures are scoped by it, and this translation is no AI answer.
    it 'names no triggering object' do
      expect(translate[:analytics_run].triggered_by).to be_nil
    end

    it 'links a regeneration back to the run it replaces' do
      previous = create(:ai_analytics_run)

      expect(translate(regeneration_of: previous)[:analytics_run].regeneration_of).to eq(previous)
    end

    it 'records none for a translation served from the store' do
      translate

      expect { translate }.not_to change(AI::Analytics::Run, :count)
    end

    it 'serves the recorded one along with the stored translation' do
      recorded = translate[:analytics_run]

      expect(translate[:analytics_run]).to eq(recorded)
    end
  end

  it 'asks DeepL for the code it knows the locale under' do
    translate

    expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target_lang' => 'DE'))
  end

  describe 'preserving the structure of the content' do
    it 'asks DeepL to keep the markup' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('tag_handling' => 'html', 'text' => [content]))
    end

    context 'with plain text content' do
      let(:html)        { false }
      let(:content)     { 'Hello world.' }
      let(:translation) { 'Hallo Welt.' }

      it 'asks for no tag handling' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with { |request| !JSON.parse(request.body).key?('tag_handling') }
      end

      it 'returns the translation' do
        expect(translate).to include(content: translation, fresh: true)
      end
    end

    context 'when DeepL does not take the content as markup' do
      before do
        stub_request(:post, endpoint)
          .with(body: hash_including('tag_handling' => 'html'))
          .to_return(status: 400, body: { message: 'Bad request. Reason: invalid tags.' }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, endpoint)
          .with { |request| !JSON.parse(request.body).key?('tag_handling') }
          .to_return(status: 200, body: { translations: [{ text: "Hallo\nWelt." }] }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'sends the content again without its markup' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('text' => ['Hello world.']))
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

      it 'records no analytics run' do
        expect { translate }.not_to change(AI::Analytics::Run, :count)
      end
    end

    context 'when DeepL answers with an empty translation' do
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

  # Which failure the client maps onto which of its own errors is its spec's matter; this one covers
  # that none of them reaches a caller unmapped.
  describe 'mapping a failure onto one of the outcomes' do
    it 'maps a refused key onto invalid credentials' do
      stub_refusal(403, 'Authorization failed')

      expect { translate }.to raise_error(described_class::InvalidCredentialsError)
    end

    it 'maps an exhausted quota onto quota exhausted' do
      stub_refusal(456, 'Quota exceeded')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    it 'maps a refused request size onto content too large' do
      stub_refusal(413, 'Request Entity Too Large')

      expect { translate }.to raise_error(described_class::ContentTooLargeError)
    end

    it 'maps a target DeepL dropped onto unsupported language' do
      stub_refusal(400, "Value for 'target_lang' not supported.")

      expect { translate }.to raise_error(described_class::UnsupportedLanguageError)
    end

    # Every request has to come out as one of the outcomes rather than escaping untyped.
    it 'maps an answer none of the outcomes describes onto unreachable' do
      stub_refusal(404, 'Not found')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    describe 'when DeepL refuses the request' do
      before { stub_refusal(403, 'Authorization failed') }

      # Only a refused markup is retried, and that one is answered before the outcome is picked.
      it 'makes no second request' do
        suppress(described_class::Error) { translate }

        expect(WebMock).to have_requested(:post, endpoint).once
      end

      it 'stores nothing' do
        expect { suppress(described_class::Error) { translate } }.not_to change(AI::StoredResult, :count)
      end
    end
  end

  describe 'the target language' do
    # From the file rather than from the locales table, which carries what the last Locale.sync
    # wrote and can be a locale behind.
    let(:active_locales) do
      YAML.load_file(Rails.root.join('config/locales.yml')).select { |entry| entry['active'] }.pluck('locale')
    end

    # DeepL spells a few of Zammad's locales with a region, and a few others not at all.
    {
      'de-de' => 'DE',
      # DeepL serves no Canadian English.
      'en-ca' => 'EN-GB',
      'en-gb' => 'EN-GB',
      'en-us' => 'EN-US',
      'pt-br' => 'PT-BR',
      'pt-pt' => 'PT-PT',
      'zh-cn' => 'ZH-HANS',
      'zh-tw' => 'ZH-HANT',
      'no-no' => 'NB',
      'fr-ca' => 'FR-CA',
      'es-mx' => 'ES-419',
    }.each do |zammad_locale, deepl_code|
      context "with the #{zammad_locale} locale" do
        let(:locale) { Locale.find_by(locale: zammad_locale) }

        it "asks for #{deepl_code}" do
          translate

          expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target_lang' => deepl_code))
        end
      end
    end

    context 'with a locale DeepL does not serve' do
      let(:locale) { Locale.find_by(locale: 'rw') }

      it 'raises' do
        expect { translate }.to raise_error(described_class::UnsupportedLanguageError, %r{rw})
      end

      # The point of the table: an unsupported target must fail rather than come back as content
      # that was never translated.
      it 'sends no content' do
        suppress(described_class::Error) { translate }

        expect(WebMock).not_to have_requested(:post, endpoint)
      end

      it 'stores nothing' do
        expect { suppress(described_class::Error) { translate } }.not_to change(AI::StoredResult, :count)
      end

      it 'still serves what is stored' do
        Service::ContentTranslation::StoredTranslation
          .save(object: article, locale:, content:, html:, backend: 'deepl', translation:)

        expect(translate).to include(content: translation, fresh: false)
      end
    end

    # Adding a locale to config/locales.yml has to be a decision about its DeepL target rather than
    # a silent refusal of the new language.
    it 'names every active locale DeepL does not serve' do
      expect(active_locales - described_class::LANGUAGE_CODES.keys).to contain_exactly('rw', 'sr-cyrl-rs', 'sr-latn-rs')
    end

    # A locale that left config/locales.yml must not keep a target of its own here.
    it 'maps active locales only' do
      expect(described_class::LANGUAGE_CODES.keys - active_locales).to be_empty
    end
  end

  describe 'the store' do
    it 'serves a second translation from it' do
      translate

      expect(translate).to include(content: translation, backend: 'deepl', fresh: false)
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
        .save(object: article, locale:, content:, html:, backend: 'libre_translate', translation: '<p>Von der Instanz.</p>')

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

  describe 'the configuration' do
    it 'names the key and the tier as required' do
      expect(described_class.required_config_keys).to contain_exactly('api_key', 'tier')
    end

    context 'with the pro tier configured' do
      let(:tier)     { 'pro' }
      let(:endpoint) { 'https://api.deepl.com/v2/translate' }

      it 'asks the host of that tier' do
        translate

        expect(WebMock).to have_requested(:post, endpoint)
      end
    end
  end

  describe 'the connection test' do
    def ping
      described_class.ping!({ api_key:, tier: })
    end

    it 'passes for a key DeepL accepts' do
      expect { ping }.not_to raise_error
    end

    # A key of the tier that was not selected is refused just like a wrong key, and nothing in the
    # answer tells the two apart.
    it 'maps a refused key onto invalid credentials' do
      stub_refusal(403, 'Authorization failed')

      expect { ping }.to raise_error(described_class::InvalidCredentialsError)
    end

    it 'maps a host that does not answer onto unreachable' do
      stub_refusal(503, 'Service Unavailable')

      expect { ping }.to raise_error(described_class::UnreachableError)
    end

    # Only the two tiers can be picked in the form, but the setting takes any value over the API.
    it 'maps a tier no host is known for onto unreachable' do
      expect { described_class.ping!({ api_key:, tier: 'enterprise' }) }
        .to raise_error(described_class::UnreachableError)
    end

    # Refusing the configuration over an exhausted quota would leave the admin with nothing to
    # correct: DeepL took the key, which is what this test asks.
    it 'accepts a refusal that says nothing about the key' do
      stub_refusal(456, 'Quota exceeded')

      expect { ping }.not_to raise_error
    end

    context 'with the pro tier configured' do
      let(:tier)     { 'pro' }
      let(:endpoint) { 'https://api.deepl.com/v2/translate' }

      it 'proves the key against the host of that tier' do
        ping

        expect(WebMock).to have_requested(:post, endpoint)
      end
    end
  end
end
