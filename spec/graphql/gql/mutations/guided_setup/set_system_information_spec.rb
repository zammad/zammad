# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What setting the system information does is covered by spec/services/service/system/set_system_information_spec.rb —
#   this covers the GraphQL surface only: authorization, the logo scalar, how the service's errors reach the client,
#   and the payload.
RSpec.describe Gql::Mutations::GuidedSetup::SetSystemInformation, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation guidedSetupSetSystemInformation($input: SystemInformation!) {
        guidedSetupSetSystemInformation(input: $input) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:variables) { { input: { url: 'http://example.com', organization: 'Sample' } } }

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before { gql.execute(query, variables: variables) }

    it_behaves_like 'graphql responds with forbidden'
  end

  context 'when unauthenticated' do
    before { gql.execute(query, variables: variables) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when setting up a new system', authenticated_as: :admin do
    let(:required_variables) do
      {
        url:          'http://example.com',
        organization: 'Sample'
      }
    end

    let(:admin) { create(:admin) }

    describe 'setting textual values' do
      context 'when locale is given' do
        let(:variables) { { input: required_variables.merge(localeDefault: 'lt') } }

        it 'sets locale' do
          expect { gql.execute(query, variables: variables) }
            .to change { Setting.get('locale_default') }
            .to('lt')
        end

        it 'returns success' do
          gql.execute(query, variables: variables)

          expect(gql.result.data)
            .to include(
              'success' => true,
            )
        end
      end
    end

    describe 'setting a required value' do
      context 'when url is not valid' do
        let(:variables) { { input: required_variables.merge(url: 'meh') } }

        it 'returns an error' do
          gql.execute(query, variables: variables)

          expect(gql.result.data)
            .to include(
              'success' => nil,
              'errors'  => include(
                'message' => 'Please include a valid url.', 'field' => 'url'
              )
            )
        end
      end
    end

    describe 'setting logo' do
      let(:image_data) { Base64.strict_encode64 Rails.root.join('test/data/image/1000x1000.png').binread }

      before do
        freeze_time

        allow(Service::SystemAssets::ProductLogo)
          .to receive(:store_one)
          .and_call_original
      end

      context 'when logo is given' do
        let(:variables) { { input: required_variables.merge(logo: image_data) } }

        it 'sets updates logo and sets logo timestamp' do
          expect { gql.execute(query, variables: variables) }
            .to change { Setting.get('product_logo') }
            .to(Time.current.to_i)
        end
      end
    end
  end
end
