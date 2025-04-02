# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ldap', type: :request do
  let!(:admin) do
    create(:admin, groups: Group.all)
  end

  describe 'discover' do
    let(:params) do
      {
        name:       'Example LDAP',
        host:       'example.ldap.okta.com',
        ssl:        'ssl',
        ssl_verify: true,
        active:     'true'
      }
    end

    context 'when disallow bin anon is active' do
      it 'returns special exception treatment for not allowed anonymous bind' do
        authenticated_as(admin)

        post '/api/v1/integration/ldap/discover', params: params, as: :json

        expect(json_response).to eq('result' => 'ok', 'error' => 'disallow-bind-anon')
      end

      context 'with other error code' do
        let(:ldap_instance) { instance_double(Net::LDAP) }
        let(:params) do
          {
            name:   'Example LDAP',
            host:   'localhost',
            ssl:    'off',
            active: 'true'
          }
        end
        let(:operation_result_struct) { Struct.new(:code, :message) }

        before do
          allow(Net::LDAP).to receive(:new).with({ host: params[:host], port: 389 }).and_return(ldap_instance)
          allow(ldap_instance).to receive_messages(
            bind:                 false,
            get_operation_result: operation_result_struct.new(50, 'Insufficient Access Rights')
          )
        end

        it 'returns special exception treatment for not allowed anonymous bind' do
          authenticated_as(admin)

          post '/api/v1/integration/ldap/discover', params: params, as: :json

          expect(json_response).to eq('result' => 'ok', 'error' => 'disallow-bind-anon')
        end
      end
    end
  end
end
