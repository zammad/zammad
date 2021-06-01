# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'RobotsTxt', type: :request do

  context 'when no Knowledge Base exists' do

    before do
      get '/robots.txt'
    end

    it 'returns success' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns text' do
      expect(response.content_type).to eq('text/plain')
    end

    it 'returns robot instructions' do
      expect(response.body).to include('Allow:').and(include('Disallow:'))
    end
  end

  context 'when Knowledge Base exists' do

    let(:custom_address) { nil }
    let(:server_name)    { Setting.get('fqdn') }

    before do
      create(:knowledge_base, custom_address: custom_address)
      get '/robots.txt', headers: { SERVER_NAME: server_name }
    end

    it 'returns robot instructions' do
      expect(response.body).to include('Allow:').and(include('Disallow:'))
    end

    context 'when custom path is configured' do
      let(:custom_address) { '/knowledge_base' }

      it 'returns rules with custom path' do
        expect(response.body).to match(%r{^Allow: /knowledge_base$}).and match(%r{^Disallow: /$})
      end
    end

    context 'when custom domain is configured' do
      let(:custom_address) { 'kb.com/knowledge_base' }

      context 'when requesting main domain' do # rubocop:disable RSpec/NestedGroups

        it 'returns default rules' do
          expect(response.body).to include('Allow:').and(include('Disallow:'))
        end
      end

      context 'when requesting KB domain' do # rubocop:disable RSpec/NestedGroups
        let(:server_name) { 'kb.com' }

        it 'returns domain rules' do
          expect(response.body).to match(%r{^Allow: /$}).and satisfy { |val| !val.match?(%r{^Disallow}) }
        end
      end
    end
  end
end
