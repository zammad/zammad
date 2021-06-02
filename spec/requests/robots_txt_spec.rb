# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'RobotsTxt', type: :request do
  shared_examples 'returns default robot instructions' do
    it 'returns default robot instructions' do
      expect(response.body).to match(%r{^Allow: /help/$}).and match(%r{^Disallow: /$})
    end
  end

  context 'when no Knowledge Base exists' do

    before do
      get '/robots.txt'
    end

    it 'returns success' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns text' do
      expect(response.content_type).to start_with('text/plain')
    end

    include_examples 'returns default robot instructions'
  end

  context 'when Knowledge Base exists' do

    let(:custom_address) { nil }
    let(:server_name)    { Setting.get('fqdn') }

    before do
      create(:knowledge_base, custom_address: custom_address)
      get '/robots.txt', headers: { SERVER_NAME: server_name }
    end

    include_examples 'returns default robot instructions'

    context 'when custom path is configured' do
      let(:custom_address) { '/knowledge_base' }

      it 'returns rules with custom path' do
        expect(response.body).to match(%r{^Allow: /knowledge_base$}).and match(%r{^Disallow: /$})
      end
    end

    context 'when custom domain is configured' do
      let(:custom_address) { 'kb.com/knowledge_base' }

      context 'when requesting main domain' do
        include_examples 'returns default robot instructions'
      end

      context 'when requesting KB domain' do
        let(:server_name) { 'kb.com' }

        it 'returns domain rules' do
          expect(response.body).to match(%r{^Allow: /$}).and satisfy { |val| !val.match?(%r{^Disallow}) }
        end
      end
    end
  end
end
