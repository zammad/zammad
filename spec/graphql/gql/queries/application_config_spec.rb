# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::ApplicationConfig, type: :graphql do

  context 'when fetching the application config' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query applicationConfig {
          applicationConfig {
            key
            value
          }
        }
      QUERY
    end

    let(:setting) { nil }

    before do
      setting
      gql.execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'returns public data' do
        expect(gql.result.data).to include({ 'key' => 'product_name', 'value' => Setting.get('product_name') })
      end

      it 'returns internal data' do
        expect(gql.result.data).to include({ 'key' => 'system_id', 'value' => Setting.get('system_id') })
      end

      it 'returns data for Rails.application.config' do
        expect(gql.result.data).to include({
                                             'key'   => 'active_storage.web_image_content_types',
                                             'value' => Rails.application.config.active_storage.web_image_content_types,
                                           })
      end

      it 'hides non-frontend data' do
        expect(gql.result.data.select { |s| s['key'].eql?('storage_provider') }).to be_empty
      end

      it 'returns no display_name for auth_saml_credentials' do
        expect(gql.result.data).to include({
                                             'key'   => 'auth_saml_credentials.display_name',
                                             'value' => nil,
                                           })
      end

      context 'when display_name for auth_saml_credentials is changed' do
        let(:setting) { Setting.set('auth_saml_credentials', Setting.get('auth_saml_credentials').merge(display_name: 'Zammad SAML')) }

        it 'returns changed display_name' do
          expect(gql.result.data).to include({
                                               'key'   => 'auth_saml_credentials.display_name',
                                               'value' => 'Zammad SAML',
                                             })
        end
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'returns public data' do
        expect(gql.result.data).to include({ 'key' => 'product_name', 'value' => Setting.get('product_name') })
      end

      it 'hides internal data' do
        expect(gql.result.data.select { |s| s['key'].eql?('system_id') }).to be_empty
      end
      # Not sure why, but that's how it is implemented...

      it 'hides all false values' do
        expect(gql.result.data.reject { |s| s['value'] }).to be_empty
      end

      it 'hides non-frontend data' do
        expect(gql.result.data.select { |s| s['key'].eql?('storage_provider') }).to be_empty
      end

      it 'returns no custom data if no changes are made' do
        expect(gql.result.data).not_to include({
                                                 'key'   => 'auth_saml_credentials.display_name',
                                                 'value' => nil,
                                               })
      end

      context 'when display_name for auth_saml_credentials is changed' do
        let(:setting) { Setting.set('auth_saml_credentials', Setting.get('auth_saml_credentials').merge(display_name: 'Zammad SAML')) }

        it 'returns custom data if changes are made' do
          expect(gql.result.data).to include({
                                               'key'   => 'auth_saml_credentials.display_name',
                                               'value' => 'Zammad SAML',
                                             })
        end
      end
    end
  end
end
