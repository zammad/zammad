# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Macro', authenticated_as: :user, type: :request do
  let(:successful_params) do
    {
      name:            'asd',
      perform:         {
        'ticket.state_id': {
          value: '2'
        }
      },
      ux_flow_next_up: 'none',
      note:            '',
      group_ids:       nil,
      active:          true
    }
  end

  describe '#create' do
    before do
      post '/api/v1/macros', params: successful_params, as: :json
    end

    context 'when user is not allowed to create macro' do
      let(:user) { create(:agent) }

      it 'does not create macro' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is allowed to create macros' do
      let(:user) { create(:admin) }

      it 'creates macro' do
        expect(response).to have_http_status(:created)
      end
    end
  end

  describe '#update' do
    let(:macro) { create(:macro, name: 'test') }

    before do
      put "/api/v1/macros/#{macro.id}", params: successful_params, as: :json
    end

    context 'when user is not allowed to update macro' do
      let(:user) { create(:agent) }

      it 'does not update macro' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'macro is not changed' do
        expect(macro.reload.name).to eq 'test'
      end
    end

    context 'when user is allowed to update macros' do
      let(:user) { create(:admin) }

      it 'request is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'macro is changed' do
        expect(macro.reload.name).to eq 'asd'
      end
    end
  end

  describe '#destroy' do
    let(:macro) { create(:macro) }

    before do
      delete "/api/v1/macros/#{macro.id}", as: :json
    end

    context 'when user is not allowed to destroy macro' do
      let(:user) { create(:agent) }

      it 'does not destroy macro' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'macro is not destroyed' do
        expect(macro).not_to be_destroyed
      end
    end

    context 'when user is allowed to create macros' do
      let(:user) { create(:admin) }

      it 'request is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'macro is destroyed' do
        expect(Macro).not_to be_exist(macro.id)
      end
    end
  end

  describe '#index' do
    before do
      get '/api/v1/macros', as: :json
    end

    context 'when user is not allowed to use macros' do
      let(:user) { create(:customer) }

      it 'returns exception' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is allowed to use macros' do
      let(:user) { create(:agent) }

      it 'request is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns array of macros' do
        expect(json_response.pluck('id')).to eq [Macro.first.id]
      end
    end

    context 'when user is admin only' do
      let(:user) { create(:admin_only) }

      it 'returns array of macros' do
        expect(json_response.pluck('id')).to eq [Macro.first.id]
      end
    end
  end

  describe '#show' do
    let(:macro) { create(:macro, groups: [create(:group)]) }

    before do
      get "/api/v1/macros/#{macro.id}", as: :json
    end

    context 'when user is not allowed to use macros' do
      let(:user) { create(:customer) }

      it 'returns exception' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is allowed to use macros' do
      let(:user) { create(:agent) }

      it 'returns exception when user has no access to related group' do
        expect(response).to have_http_status(:not_found)
      end

      context 'when user has acess to this group' do
        let(:user) { create(:agent, groups: macro.groups) }

        it 'returns macro when user has access to related group' do
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'when user is admin only' do
      let(:user) { create(:admin_only) }

      it 'returns array of macros' do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
