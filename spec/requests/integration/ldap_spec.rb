# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
    end
  end
end
