# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DeepL::Client do
  let(:tier)     { 'free' }
  let(:api_key)  { 'secret-key' }
  let(:endpoint) { 'https://api-free.deepl.com/v2/translate' }
  let(:client)   { described_class.new(tier:, api_key:) }

  # What DeepL answers, in the shape UserAgent parses as JSON.
  def stub_translate(text)
    stub_request(:post, endpoint)
      .to_return(status: 200, body: { translations: [{ detected_source_language: 'EN', text: }] }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_refusal(status, message)
    stub_request(:post, endpoint)
      .to_return(status:, body: { message: }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def translate(html: false)
    client.translate(text: 'Hello world.', target: 'DE', html:)
  end

  describe '#translate' do
    before { stub_translate('Hallo Welt.') }

    it 'returns the translated text' do
      expect(translate).to eq('Hallo Welt.')
    end

    it 'asks for the given target' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target_lang' => 'DE'))
    end

    # DeepL takes the content as a list rather than as a single string.
    it 'sends the content as a list' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('text' => ['Hello world.']))
    end

    it 'lets DeepL detect the source language' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with { |request| !JSON.parse(request.body).key?('source_lang') }
    end

    it 'authenticates with the API key' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with(headers: { 'Authorization' => "DeepL-Auth-Key #{api_key}" })
    end

    it 'asks for no tag handling by default' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with { |request| !JSON.parse(request.body).key?('tag_handling') }
    end

    it 'asks DeepL to keep the markup for HTML content' do
      translate(html: true)

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('tag_handling' => 'html'))
    end

    context 'with the pro tier configured' do
      let(:tier)     { 'pro' }
      let(:endpoint) { 'https://api.deepl.com/v2/translate' }

      it 'asks the other host' do
        translate

        expect(WebMock).to have_requested(:post, endpoint)
      end
    end

    # A proxy or a captive portal can answer 200 with something else entirely; taking it for a
    # translation would hand the caller an empty article.
    context 'when the answer carries no translation' do
      it 'raises for an answer that is no object' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })

        expect { translate }.to raise_error(described_class::UnreachableError)
      end

      it 'raises for an object without the translations' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: { message: 'hello' }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect { translate }.to raise_error(described_class::UnreachableError)
      end

      it 'raises for an empty list of translations' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: { translations: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect { translate }.to raise_error(described_class::UnreachableError)
      end
    end
  end

  describe 'mapping a refusal onto an error' do
    it 'maps a host that does not answer onto unreachable' do
      stub_request(:post, endpoint).to_timeout

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    it 'maps a server error onto unreachable' do
      stub_refusal(500, 'Internal error')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    it 'maps an unavailable service onto unreachable' do
      stub_refusal(503, 'Resource currently unavailable. Try again later.')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    it 'maps a refused API key onto invalid credentials' do
      stub_refusal(403, 'Authorization failed')

      expect { translate }.to raise_error(described_class::InvalidCredentialsError)
    end

    it 'maps an exhausted rate limit onto quota exhausted' do
      stub_refusal(429, 'Too many requests')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    # DeepL keeps a status of its own for the account quota, apart from the rate limit.
    it 'maps an exhausted account quota onto quota exhausted' do
      stub_refusal(456, 'Quota exceeded')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    # DeepL answers a rate limit with 529 as well, which sits in the range its server errors use.
    it 'maps a rate limit above the server error range onto quota exhausted' do
      stub_refusal(529, 'Too many requests. Please wait and resend your request.')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    it 'maps a refused request size onto content too large' do
      stub_refusal(413, 'Request Entity Too Large')

      expect { translate }.to raise_error(described_class::ContentTooLargeError)
    end

    it 'maps a target DeepL does not serve onto unsupported language' do
      stub_refusal(400, "Value for 'target_lang' not supported.")

      expect { translate }.to raise_error(described_class::UnsupportedLanguageError)
    end

    # The caller can send the same content again as plain text, so it is an error of its own.
    it 'maps a bad request while keeping the markup onto its own error' do
      stub_refusal(400, 'Bad request. Reason: invalid tags.')

      expect { translate(html: true) }.to raise_error(described_class::HtmlRefusedError)
    end

    # Only markup can be sent again differently; nothing else about the request would change.
    it 'does not take a bad request for plain text for that' do
      stub_refusal(400, 'Bad request. Reason: invalid tags.')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    # A refused target language shares its status with the refused markup.
    it 'does not take a refused target language for a refused markup' do
      stub_refusal(400, "Value for 'target_lang' not supported.")

      expect { translate(html: true) }.to raise_error(described_class::UnsupportedLanguageError)
    end

    # Every request has to come out as one of the errors rather than escaping untyped.
    it 'maps an answer none of the errors describes onto unreachable' do
      stub_refusal(404, 'Not found')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    # The admin form offers the two tiers only, so this is a config written by hand.
    it 'maps a tier that names no host onto unreachable' do
      expect { described_class.new(tier: 'enterprise', api_key:).translate(text: 'Hello', target: 'DE') }
        .to raise_error(described_class::UnreachableError)
    end
  end

  describe 'logging every request' do
    before { stub_translate('Hallo Welt.') }

    it 'logs a translation' do
      expect { translate }.to change { HttpLog.where(facility: 'content_translation', url: endpoint).count }.by(1)
    end

    it 'does not log the API key' do
      translate

      expect(HttpLog.last.request['content']).not_to include(api_key)
    end

    it 'masks it' do
      translate

      expect(HttpLog.last.request['content']).to include('[FILTERED]')
    end
  end
end
