# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

# Custom subdomain is handled by rewriting at web server
# Calling the original /help URL with a custom URL in header to simulate
RSpec.describe 'KnowledgeBase public custom path', type: :request do
  let!(:knowledge_base) { create(:knowledge_base, custom_address: custom_address) }
  let(:path)            { '/path' }
  let(:subdomain)       { 'subdomain.example.net' }
  let(:locale)          { knowledge_base.kb_locales.first.system_locale.locale }

  shared_examples 'accepting original URL' do
    before { fetch }

    it { expect(response).to have_http_status(:found) }
    it { expect(response).to redirect_to "/help/#{locale}" }
  end

  context 'with no custom path' do
    let(:custom_address) { nil }

    it_behaves_like 'accepting original URL'

    context 'when called with the subdomain' do
      before { fetch subdomain: subdomain, path: '/' }

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to "/help/#{locale}" }
    end
  end

  context 'with custom path' do
    let(:custom_address) { path }

    it_behaves_like 'accepting original URL'

    context 'when called with the path' do
      before { fetch path: path }

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to "/path/#{locale}" }
    end

    context 'when called with a custom port' do
      before { fetch path: path, port: 8080 }

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to ":8080/path/#{locale}" }
    end

    context 'when called with the path and subdomain' do
      before { fetch path: path, subdomain: subdomain }

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to "http://subdomain.example.net/path/#{locale}" }
    end
  end

  context 'with custom subdomain' do
    let(:custom_address) { subdomain }

    it_behaves_like 'accepting original URL'

    context 'when called with the subdomain' do
      before { fetch subdomain: subdomain, path: '/' }

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to "http://subdomain.example.net/#{locale}" }
    end
  end

  context 'with custom subdomain and path' do
    let(:custom_address) { "#{subdomain}#{path}" }

    it_behaves_like 'accepting original URL'

    context 'when called with the path and subdomain' do
      before { fetch path: path, subdomain: subdomain }

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to "http://subdomain.example.net/path/#{locale}" }
    end
  end

  def fetch(path: nil, subdomain: nil, port: nil)
    headers = { HTTP_X_ORIGINAL_URL: path, SERVER_NAME: subdomain, SERVER_PORT: port }.compact

    get '/help', headers: headers
  end
end
