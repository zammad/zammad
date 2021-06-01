# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GettingStartedController do
  describe '.validate_uri' do
    it 'false for nil' do
      expect(described_class.validate_uri(nil)).to be_falsey
    end

    it 'false for empty' do
      expect(described_class.validate_uri('')).to be_falsey
    end

    it 'false for non-http(s)' do
      expect(described_class.validate_uri('a://example.org')).to be_falsey
    end

    it 'false for gibberish uri' do
      expect(described_class.validate_uri('http:///a')).to be_falsey
    end

    it 'http and fqdn for http' do
      expect(described_class.validate_uri('http://example.org')).to eq({ scheme: 'http', fqdn: 'example.org' })
    end

    it 'https and fqdn for https' do
      expect(described_class.validate_uri('https://example.org')).to eq({ scheme: 'https', fqdn: 'example.org' })
    end

    it 'http and fqdn for http on default port' do
      expect(described_class.validate_uri('http://example.org:80')).to eq({ scheme: 'http', fqdn: 'example.org' })
    end

    it 'https and fqdn for https on default port' do
      expect(described_class.validate_uri('https://example.org:443')).to eq({ scheme: 'https', fqdn: 'example.org' })
    end

    it 'http and fqdn with port for http on custom port' do
      expect(described_class.validate_uri('http://example.org:443')).to eq({ scheme: 'http', fqdn: 'example.org:443' })
    end

    it 'https and fqdn with port for https on custom port' do
      expect(described_class.validate_uri('https://example.org:80')).to eq({ scheme: 'https', fqdn: 'example.org:80' })
    end
  end
end
