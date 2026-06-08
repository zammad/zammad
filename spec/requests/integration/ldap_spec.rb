# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ldap', type: :request do
  let(:admin) { create(:admin, groups: Group.all) }

  describe 'POST /api/v1/integration/ldap/discover' do
    let(:base_params) do
      {
        name:   'Example LDAP',
        host:   'localhost',
        ssl:    'off',
        active: 'true'
      }
    end

    context 'when LDAP server does not allow anonymous bind' do
      let(:ldap_instance) { instance_double(Net::LDAP) }
      let(:operation_result) { Struct.new(:code, :message).new(error_code, error_message) }

      before do
        allow(Net::LDAP).to receive(:new).with({ host: base_params[:host], port: 389 }).and_return(ldap_instance)
        allow(ldap_instance).to receive_messages(bind: false, get_operation_result: operation_result)
      end

      # LDAP error 50 = Insufficient Access Rights
      # LDAP error 53 = Unwilling to perform
      # See: https://ldap.com/ldap-result-code-reference
      [
        { code: 50, message: 'Insufficient Access Rights' },
        { code: 53, message: 'Unwilling to perform' },
      ].each do |error|
        context "with error code #{error[:code]} - #{error[:message]}" do
          let(:error_code)    { error[:code] }
          let(:error_message) { error[:message] }

          it 'returns disallow-bind-anon error' do
            authenticated_as(admin)

            post '/api/v1/integration/ldap/discover', params: base_params, as: :json

            expect(json_response).to include('result' => 'ok', 'error' => 'disallow-bind-anon')
          end
        end
      end
    end
  end

  describe 'bind' do
    let(:params) { { bind_pw: 'test' } }

    context 'with unmasked password' do
      it 'uses the password' do
        authenticated_as(admin)

        allow(Ldap).to receive(:new).and_call_original
        post '/api/v1/integration/ldap/bind', params: params, as: :json
        expect(Ldap).to have_received(:new).with(hash_including(bind_pw: 'test'))
      end
    end

    context 'with masked password' do
      let!(:ldap_source) do
        create(:ldap_source, :with_config).tap do |ls|
          ls.preferences[:bind_pw] = 'stored_password'
          ls.save!
        end
      end
      let(:params) { { ldap_source_id: ldap_source.id, bind_pw: SensitiveParamsHelper::SENSITIVE_MASK } }

      it 'uses the stored password' do
        authenticated_as(admin)

        allow(Ldap).to receive(:new).and_call_original

        post '/api/v1/integration/ldap/bind', params: params, as: :json

        expect(Ldap).to have_received(:new).with(hash_including(bind_pw: 'stored_password'))
      end
    end
  end
end
