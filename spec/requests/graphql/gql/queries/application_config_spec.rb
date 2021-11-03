# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::ApplicationConfig, type: :request do

  context 'when fetching the application config' do
    let(:agent) { create(:agent) }
    let(:query) { File.read(Rails.root.join('app/frontend/apps/mobile/graphql/queries/applicationConfig.graphql')) }
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'returns public data' do
        expect(graphql_response['data']['applicationConfig']).to include({ 'key' => 'product_name', 'value' => Setting.get('product_name') })
      end

      it 'returns internal data' do
        expect(graphql_response['data']['applicationConfig']).to include({ 'key' => 'system_id', 'value' => Setting.get('system_id') })
      end

      it 'hides non-frontend data' do
        expect(graphql_response['data']['applicationConfig'].select { |s| s['key'].eql?('storage_provider') }).to be_empty
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'returns public data' do
        expect(graphql_response['data']['applicationConfig']).to include({ 'key' => 'product_name', 'value' => Setting.get('product_name') })
      end

      it 'hides internal data' do
        expect(graphql_response['data']['applicationConfig'].select { |s| s['key'].eql?('system_id') }).to be_empty
      end
      # Not sure why, but that's how it is implemented...

      it 'hides all false values' do
        expect(graphql_response['data']['applicationConfig'].reject { |s| s['value'] }).to be_empty
      end

      it 'hides non-frontend data' do
        expect(graphql_response['data']['applicationConfig'].select { |s| s['key'].eql?('storage_provider') }).to be_empty
      end
    end
  end
end
