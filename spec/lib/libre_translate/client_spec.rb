# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe LibreTranslate::Client do
  let(:url)                { 'https://translate.example.com' }
  let(:endpoint)           { "#{url}/translate" }
  let(:languages_endpoint) { "#{url}/languages" }
  let(:api_key)            { nil }
  let(:client)             { described_class.new(url:, api_key:) }

  before { stub_hostname_resolution(url) }

  # What the instance answers, in the shape UserAgent parses as JSON.
  def stub_translate(text)
    stub_request(:post, endpoint)
      .to_return(status: 200, body: { translatedText: text }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_languages(codes)
    stub_request(:get, languages_endpoint)
      .to_return(status: 200, body: codes.map { |code| { code: } }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_refusal(status, error)
    stub_request(:post, endpoint)
      .to_return(status:, body: { error: }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def translate(format: 'text')
    client.translate(text: 'Hello world.', target: 'de', format:)
  end

  describe '#translate' do
    before { stub_translate('Hallo Welt.') }

    it 'returns the translated text' do
      expect(translate).to eq('Hallo Welt.')
    end

    it 'lets the instance detect the source language' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('source' => 'auto'))
    end

    it 'asks for the given target and format' do
      translate(format: 'html')

      expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('target' => 'de', 'format' => 'html'))
    end

    it 'sends no API key while none is configured' do
      translate

      expect(WebMock).to have_requested(:post, endpoint).with { |request| !JSON.parse(request.body).key?('api_key') }
    end

    context 'with an API key configured' do
      let(:api_key) { 'secret-key' }

      it 'sends it' do
        translate

        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including('api_key' => api_key))
      end
    end

    # What a URL pointing at something else than a LibreTranslate instance answers with. Taking it
    # for a translation would hand the caller an empty article.
    context 'when the answer carries no translated text' do
      it 'raises for an answer that is no object' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })

        expect { translate }.to raise_error(described_class::UnreachableError)
      end

      it 'raises for an object without the text' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: { message: 'hello' }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect { translate }.to raise_error(described_class::UnreachableError)
      end
    end
  end

  describe 'mapping a refusal onto an error' do
    it 'maps a host that does not answer onto unreachable' do
      stub_request(:post, endpoint).to_timeout

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    it 'maps a URL no request can be built from onto unreachable' do
      expect { described_class.new(url: 'translate.example.com').translate(text: 'Hello', target: 'de', format: 'text') }
        .to raise_error(described_class::UnreachableError)
    end

    it 'maps a URL with another scheme than HTTP onto unreachable' do
      expect { described_class.new(url: 'ftp://translate.example.com').translate(text: 'Hello', target: 'de', format: 'text') }
        .to raise_error(described_class::UnreachableError)
    end

    it 'maps a server error onto unreachable' do
      stub_refusal(503, 'Service Unavailable')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end

    it 'maps a refused API key onto invalid credentials' do
      stub_refusal(403, 'Invalid API key')

      expect { translate }.to raise_error(described_class::InvalidCredentialsError)
    end

    it 'maps an exhausted rate limit onto quota exhausted' do
      stub_refusal(429, 'Slowdown: 60 per 1 minute')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    # The same status as a refused key, so only the wording separates the two.
    it 'maps a banned address onto quota exhausted' do
      stub_refusal(403, 'Too many request limits violations')

      expect { translate }.to raise_error(described_class::QuotaExceededError)
    end

    it 'maps an exceeded text limit onto content too large' do
      stub_refusal(400, 'Invalid request: request (5000) exceeds text limit (2000)')

      expect { translate }.to raise_error(described_class::ContentTooLargeError)
    end

    it 'maps a refused request size onto content too large' do
      stub_refusal(413, 'Request Entity Too Large')

      expect { translate }.to raise_error(described_class::ContentTooLargeError)
    end

    it 'maps a missing translation path onto unsupported language' do
      stub_refusal(400, 'de is not available as target from ja')

      expect { translate }.to raise_error(described_class::UnsupportedLanguageError)
    end

    it 'maps a language the instance has no model for onto unsupported language' do
      stub_refusal(400, 'de is not supported')

      expect { translate }.to raise_error(described_class::UnsupportedLanguageError)
    end

    # Shares its wording with a language the instance has no model for, but the caller can send the
    # same content again as plain text - so it is an error of its own.
    it 'maps a refused HTML format onto its own error' do
      stub_refusal(400, 'html format is not supported')

      expect { translate(format: 'html') }.to raise_error(described_class::HtmlFormatUnsupportedError)
    end

    # Every request has to come out as one of the errors rather than escaping untyped.
    it 'maps an answer none of the errors describes onto unreachable' do
      stub_refusal(400, 'Invalid request: missing q parameter')

      expect { translate }.to raise_error(described_class::UnreachableError)
    end
  end

  describe '#languages' do
    before { stub_languages(%w[en de]) }

    it 'returns the codes the instance serves' do
      expect(client.languages).to eq(%w[en de])
    end

    # No API key: LibreTranslate exempts this endpoint from its key check.
    context 'with an API key configured' do
      let(:api_key) { 'secret-key' }

      it 'asks without it' do
        client.languages

        expect(WebMock).to have_requested(:get, languages_endpoint).with { |request| request.uri.to_s.exclude?(api_key) }
      end
    end

    it 'asks the instance once' do
      2.times { client.languages }

      expect(WebMock).to have_requested(:get, languages_endpoint).once
    end

    it 'asks again when forced' do
      client.languages
      client.languages(force: true)

      expect(WebMock).to have_requested(:get, languages_endpoint).twice
    end

    it 'raises for a refused listing' do
      stub_request(:get, languages_endpoint).to_return(status: 503, body: 'Service Unavailable')

      expect { client.languages }.to raise_error(described_class::UnreachableError)
    end

    # What a URL pointing at something else than a LibreTranslate instance answers with. Taking it
    # for an empty list would refuse every language for as long as it is cached.
    context 'when the listing names no language' do
      before do
        stub_request(:get, languages_endpoint)
          .to_return(status: 200, body: { message: 'hello' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises' do
        expect { client.languages }.to raise_error(described_class::UnreachableError)
      end

      it 'caches nothing' do
        2.times { suppress(described_class::Error) { client.languages } }

        expect(WebMock).to have_requested(:get, languages_endpoint).twice
      end
    end
  end

  # The URL is what an admin configured, and the HTTP log keeps every answer - so a request must
  # not end up anywhere else than where that URL leads.
  describe 'where a request may go' do
    let(:elsewhere) { 'https://elsewhere.example.com/translate' }

    before { stub_hostname_resolution(elsewhere) }

    context 'when the instance redirects a translation' do
      before do
        stub_request(:post, endpoint).to_return(status: 302, headers: { 'Location' => elsewhere })
        stub_request(:get, %r{elsewhere\.example\.com})
          .to_return(status: 200, body: { translatedText: 'Hallo Welt.' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises unreachable' do
        expect { translate }.to raise_error(described_class::UnreachableError)
      end

      it 'does not follow it' do
        suppress(described_class::Error) { translate }

        expect(WebMock).not_to have_requested(:get, %r{elsewhere\.example\.com})
      end
    end

    context 'when the instance redirects the language listing' do
      before do
        stub_request(:get, languages_endpoint).to_return(status: 302, headers: { 'Location' => elsewhere })
        stub_request(:get, %r{elsewhere\.example\.com})
          .to_return(status: 200, body: [{ code: 'en' }].to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises unreachable' do
        expect { client.languages }.to raise_error(described_class::UnreachableError)
      end

      it 'does not follow it' do
        suppress(described_class::Error) { client.languages }

        expect(WebMock).not_to have_requested(:get, %r{elsewhere\.example\.com})
      end
    end

    {
      'a link-local address'                         => '169.254.169.254',
      'a link-local address in IPv6 notation'        => '::ffff:169.254.169.254',
      'the IPv6 address of a cloud metadata service' => 'fd00:ec2::254',
    }.each do |destination, ip|
      context "when the hostname leads to #{destination}" do
        before do
          stub_hostname_resolution(url, ip:)
          stub_translate('Hallo Welt.')
        end

        it 'raises unreachable' do
          expect { translate }.to raise_error(described_class::UnreachableError)
        end

        it 'asks nothing' do
          suppress(described_class::Error) { translate }

          expect(WebMock).not_to have_requested(:post, endpoint)
        end
      end
    end

    # A self-hosted instance commonly sits on the local network, or on this very host.
    context 'when the hostname leads to a private address' do
      before do
        stub_hostname_resolution(url, ip: '10.0.0.5')
        stub_translate('Hallo Welt.')
      end

      it 'asks it' do
        expect(translate).to eq('Hallo Welt.')
      end
    end

    context 'when the hostname leads to a loopback address' do
      before do
        stub_hostname_resolution(url, ip: '127.0.0.1')
        stub_translate('Hallo Welt.')
      end

      it 'asks it' do
        expect(translate).to eq('Hallo Welt.')
      end
    end
  end

  describe 'logging every request' do
    def logs_of(url)
      HttpLog.where(facility: 'content_translation', url:)
    end

    before do
      stub_languages(%w[en de])
      stub_translate('Hallo Welt.')
    end

    it 'logs a translation' do
      expect { translate }.to change { logs_of(endpoint).count }.by(1)
    end

    it 'logs the language listing' do
      expect { client.languages }.to change { logs_of(languages_endpoint).count }.by(1)
    end

    context 'with an API key configured' do
      let(:api_key) { 'secret-key' }

      it 'does not log it' do
        translate

        expect(HttpLog.last.request['content']).not_to include(api_key)
      end

      it 'masks it' do
        translate

        expect(HttpLog.last.request['content']).to include('[FILTERED]')
      end
    end
  end
end
