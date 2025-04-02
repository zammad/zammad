# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'External Data Source', :aggregate_failures, db_adapter: :postgresql, type: :request do
  let(:agent)          { create(:agent) }
  let(:admin)          { create(:admin) }
  let(:object_name)    { 'Ticket' }
  let(:attribute)      { create(:object_manager_attribute_autocompletion_ajax_external_data_source, object_name:) }
  let(:ticket)         { create(:ticket) }
  let(:url)            { "/api/v1/external_data_source/#{attribute.object_lookup.name}/#{attribute.name}?query=abc&search_context%5Bticket_id%5D=#{ticket.id}" }
  let(:preview_url)    { '/api/v1/external_data_source/preview' }
  let(:mocked_payload) { [{ 'value' => 'abc', 'label' => 'abc' }] }

  before do
    allow(ExternalDataSource).to receive(:new).and_call_original
    allow_any_instance_of(ExternalDataSource).to receive(:process).and_return(mocked_payload)
  end

  context 'without authentication' do
    describe '#fetch' do
      it 'returns 403 Forbidden' do
        get url, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end

    describe '#preview' do
      it 'returns 403 Forbidden' do
        post preview_url, params: { data_option: attribute.data_option, query: 'abc' }, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end
  end

  context 'when authenticated as agent', authenticated_as: :agent do
    describe '#fetch' do
      it 'responds with an array of ExternalCredential records' do
        get url, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq('result' => mocked_payload)
        expect(ExternalDataSource).to have_received(:new).with(include(render_context: { ticket: ticket, user: agent }))
      end

      context 'when object is Group' do
        let(:object_name) { 'Group' }

        it 'returns 403 Forbidden' do
          get url, as: :json

          expect(response).to have_http_status(:forbidden)
          expect(json_response).to include('error' => 'Not authorized')
        end
      end
    end

    describe '#preview' do
      it 'returns 403 Forbidden' do
        post preview_url, params: { data_option: attribute.data_option, query: 'abc' }, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'User authorization failed.')
      end
    end
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    describe '#preview' do
      it 'responds with an array of ExternalCredential records' do
        post preview_url, params: { data_option: attribute.data_option, query: 'abc' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq('data' => mocked_payload, 'success' => true)
        expect(ExternalDataSource).to have_received(:new).with(include(render_context: { user: admin }))
      end
    end

    describe '#fetch' do
      context 'when object is Group' do
        let(:object_name)    { 'Group' }
        let(:group)          { create(:group) }
        let(:url)            { "/api/v1/external_data_source/#{attribute.object_lookup.name}/#{attribute.name}?query=abc&search_context%5Bgroup_id%5D=#{group.id}" }

        it 'responds with an array of ExternalCredential records' do
          get url, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to eq('result' => mocked_payload)
          expect(ExternalDataSource).to have_received(:new).with(include(render_context: { group: group, user: admin }))
        end
      end

      context 'when customer is given' do
        let(:object_name) { 'Group' }
        let(:customer)    { create(:customer) }
        let(:url)         { "/api/v1/external_data_source/#{attribute.object_lookup.name}/#{attribute.name}?query=abc&search_context%5Bcustomer_id%5D=#{customer.id}" }

        it 'responds with an array of ExternalCredential records' do
          get url, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to eq('result' => mocked_payload)
          expect(ExternalDataSource)
            .to have_received(:new)
            .with(include(
                    render_context: {
                      user:   admin,
                      ticket: a_kind_of(Ticket).and(have_attributes(customer: customer))
                    }
                  ))
        end
      end
    end
  end
end
