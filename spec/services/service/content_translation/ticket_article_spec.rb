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
