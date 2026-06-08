# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe LdapSourcesController, type: :request do
  let(:agent) { create(:agent) }
  let(:admin) { create(:admin) }

  describe 'request handling', authenticated_as: :admin do
    context 'when listing ldap sources' do
      let!(:ldap_sources) do
        create_list(:ldap_source, 3, preferences: { bind_pw: 'secret_password' })
      end
      let(:url) { '/api/v1/ldap_sources.json' }

      before do
        get url
      end

      context 'without parameters' do
        it 'returns all' do
          expect(json_response.length).to eq(ldap_sources.length)
        end

        it 'masks sensitive fields' do
          expect(json_response.first['preferences']).to include(
            'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
          )
        end

        context 'with agent permissions', authenticated_as: :agent do
          it 'request is forbidden' do
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'with expand=1' do
        let(:url) { '/api/v1/ldap_sources.json?expand=1' }

        it 'returns all' do
          expect(json_response.length).to eq(ldap_sources.length)
        end

        it 'masks sensitive fields' do
          expect(json_response.first['preferences']).to include(
            'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
          )
        end
      end

      context 'with full=1' do
        let(:url) { '/api/v1/ldap_sources.json?full=1' }

        it 'returns all' do
          expect(json_response['record_ids'].length).to eq(ldap_sources.length)
        end

        it 'masks sensitive fields' do
          expect(json_response['assets']['LdapSource'][ldap_sources.first.id.to_s]['preferences']).to include(
            'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
          )
        end
      end
    end

    context 'when showing ldap source' do
      let!(:ldap_source) { create(:ldap_source, preferences: { bind_pw: 'secret_password' }) }

      before do
        get "/api/v1/ldap_sources/#{ldap_source.id}.json"
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'masks sensitive fields' do
        expect(json_response['preferences']).to include(
          'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
        )
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when creating ldap source' do
      let(:params) do
        {
          name:        'Test LDAP',
          host:        'ldap.example.com',
          port:        389,
          ssl:         false,
          active:      true,
          preferences: { bind_pw: 'new_password' }
        }
      end

      before do
        post '/api/v1/ldap_sources.json', params: params
      end

      it 'returns created' do
        expect(response).to have_http_status(:created)
      end

      it 'creates ldap source with unmasked password' do
        created_source = LdapSource.find(json_response['id'])
        expect(created_source.preferences['bind_pw']).to eq('new_password')
      end

      it 'masks sensitive fields in response' do
        expect(json_response['preferences']).to include(
          'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
        )
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when updating ldap source' do
      let!(:ldap_source) { create(:ldap_source, preferences: { bind_pw: 'original_password' }) }
      let(:params) { { name: 'Updated LDAP' } }

      before do
        put "/api/v1/ldap_sources/#{ldap_source.id}.json", params: params
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'masks sensitive fields in response' do
        expect(json_response['preferences']).to include(
          'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
        )
      end

      context 'with masked fields' do
        let(:params) do
          {
            name:        'Updated LDAP',
            preferences: {
              bind_pw: SensitiveParamsHelper::SENSITIVE_MASK
            }
          }
        end

        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'masks sensitive fields in response' do
          expect(json_response['preferences']).to include(
            'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
          )
        end

        it 'keeps original field values when masked' do
          expect(ldap_source.reload.preferences['bind_pw']).to eq('original_password')
        end
      end

      context 'with new password value' do
        let(:params) do
          {
            name:        'Updated LDAP',
            preferences: { bind_pw: 'new_updated_password' }
          }
        end

        it 'updates the password when not masked' do
          expect(ldap_source.reload.preferences['bind_pw']).to eq('new_updated_password')
        end

        it 'masks sensitive fields in response' do
          expect(json_response['preferences']).to include(
            'bind_pw' => SensitiveParamsHelper::SENSITIVE_MASK
          )
        end
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when destroying ldap source' do
      let!(:ldap_source) { create(:ldap_source, preferences: { bind_pw: 'secret_password' }) }

      before do
        delete "/api/v1/ldap_sources/#{ldap_source.id}.json"
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
