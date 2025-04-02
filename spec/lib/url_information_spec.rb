# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UrlInformation, :aggregate_failures do
  subject(:url_information) { described_class.new(url) }

  let(:url) { nil }

  describe '.fqdn' do
    it 'not filled when not valid' do
      expect { url_information }.to raise_error(UrlInformation::Error)
    end

    context 'with valid url' do
      let(:url) { 'http://example.org' }

      it 'fqdn and scheme' do
        expect(url_information.fqdn).to eq 'example.org'
        expect(url_information.scheme).to eq 'http'
      end
    end

    context 'with https url' do
      let(:url) { 'https://example.org' }

      it 'fqdn and scheme' do
        expect(url_information.fqdn).to eq 'example.org'
        expect(url_information.scheme).to eq 'https'
      end
    end

    context 'with http and fqdn for http on default port' do
      let(:url) { 'http://example.org:80' }

      it 'fqdn and scheme' do
        expect(url_information.fqdn).to eq 'example.org'
        expect(url_information.scheme).to eq 'http'
      end
    end

    context 'with https and fqdn for https on default port' do
      let(:url) { 'https://example.org:443' }

      it 'fqdn and scheme' do
        expect(url_information.fqdn).to eq 'example.org'
        expect(url_information.scheme).to eq 'https'
      end
    end

    context 'with https and fqdn with custom port' do
      let(:url) { 'https://example.org:5555' }

      it 'fqdn and scheme' do
        expect(url_information.fqdn).to eq 'example.org:5555'
        expect(url_information.scheme).to eq 'https'
      end
    end
  end
end
