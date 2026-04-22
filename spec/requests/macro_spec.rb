# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

PENDING_REMINDER_CATEGORY = :pending_reminder
PENDING_ACTION_CATEGORY = :pending_action

INVALID_PENDING_MACRO_NAMES = {
  PENDING_REMINDER_CATEGORY => 'pending reminder without date'.freeze,
  PENDING_ACTION_CATEGORY   => 'pending action without date'.freeze,
}.freeze

RSpec.describe 'Macro', authenticated_as: :user, type: :request do
  def persisted_pending_time_for(macro)
    Time.zone.parse(macro.perform.dig('ticket.pending_time', 'value').to_s)
  end

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

  def macro_params_pending_without_time(category)
    successful_params.deep_merge(
      name:    INVALID_PENDING_MACRO_NAMES.fetch(category),
      perform: {
        'ticket.state_id': {
          value: Ticket::State.by_category(category).first.id.to_s
        }
      }
    )
  end

  shared_examples 'persists pending time' do
    it 'accepts the request' do
      expect(response).to have_http_status(success_status)
    end

    it 'persists the pending time' do
      expect(persisted_pending_time_for(reloaded_macro)).to be_within(1.second).of(pending_time)
    end
  end

  describe '#create' do
    let(:request_params) { successful_params }

    before do
      post '/api/v1/macros', params: request_params, as: :json
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

    [PENDING_REMINDER_CATEGORY, PENDING_ACTION_CATEGORY].each do |category|
      context "when #{category} macro has no pending time" do
        let(:user) { create(:admin) }
        let(:request_params) { macro_params_pending_without_time(category) }

        it 'returns validation error' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'does not persist the macro' do
          expect(Macro.find_by(name: INVALID_PENDING_MACRO_NAMES.fetch(category))).to be_nil
        end
      end

      context "when #{category} macro is valid with pending time" do
        let(:pending_time)     { 5.minutes.from_now }
        let(:user)             { create(:admin) }
        let(:success_status)   { :created }
        let(:reloaded_macro)   { Macro.find_by!(name: INVALID_PENDING_MACRO_NAMES.fetch(category)) }
        let(:request_params) do
          macro_params_pending_without_time(category).deep_merge(
            perform: { 'ticket.pending_time': { value: pending_time } }
          )
        end

        include_examples 'persists pending time'
      end
    end
  end

  describe '#update' do
    let(:macro) { create(:macro, name: 'test') }
    let(:request_params) { successful_params }

    before do
      put "/api/v1/macros/#{macro.id}", params: request_params, as: :json
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

    [PENDING_REMINDER_CATEGORY, PENDING_ACTION_CATEGORY].each do |category|
      context "when #{category} macro has no pending time" do
        let(:user) { create(:admin) }
        let(:request_params) { macro_params_pending_without_time(category) }

        it 'returns validation error' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'does not update the macro' do
          expect(macro.reload.name).to eq 'test'
        end
      end

      context "when #{category} macro is valid with pending time" do
        let(:pending_time)     { 5.minutes.from_now }
        let(:user)             { create(:admin) }
        let(:success_status)   { :ok }
        let(:updated_name) do
          case category
          when PENDING_REMINDER_CATEGORY then 'updated pending reminder macro'
          when PENDING_ACTION_CATEGORY then 'updated pending action macro'
          end
        end
        let(:reloaded_macro) { macro.reload }
        let(:request_params) do
          macro_params_pending_without_time(category).deep_merge(
            name:    updated_name,
            perform: { 'ticket.pending_time': { value: pending_time } }
          )
        end

        include_examples 'persists pending time'

        it 'updates the macro name' do
          expect(reloaded_macro.name).to eq updated_name
        end
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
        expect(Macro).not_to exist(macro.id)
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
    let(:macro) { create(:macro, groups: create_list(:group, 1)) }

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
