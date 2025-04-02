# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::GuidedSetup::SetSystemInformation, type: :graphql do
  context 'when setting up a new system', authenticated_as: :admin do
    let(:required_variables) do
      {
        url:          'http://example.com',
        organization: 'Sample'
      }
    end

    let(:admin) { create(:admin) }

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
      context 'when url is given' do
        let(:variables) { { input: required_variables } }

        it 'sets instance name' do
          expect { gql.execute(query, variables: variables) }
            .to change { [Setting.get('http_type'), Setting.get('fqdn')] }
            .to(['http', 'example.com'])
        end

        it 'does not return any errors' do
          gql.execute(query, variables: variables)

          expect(gql.result.data).to include('success' => true, 'errors' => be_blank)
        end
      end

      context 'when url is not valid' do
        let(:variables) { { input: required_variables.merge(url: 'meh') } }

        it 'does not set http type & FQDN' do
          expect { gql.execute(query, variables: variables) }
            .not_to change { [Setting.get('http_type'), Setting.get('fqdn')] }
        end

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

      context 'when url is not given for an online service' do
        let(:variables) { { input: required_variables.tap { _1.delete(:url) } } }

        before { Setting.set('system_online_service', true) }

        it 'does not set http type & FQDN' do
          expect { gql.execute(query, variables: variables) }
            .not_to change { [Setting.get('http_type'), Setting.get('fqdn')] }
        end

        it 'does not return any errors' do
          gql.execute(query, variables: variables)

          expect(gql.result.data).to include('success' => true, 'errors' => be_blank)
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
