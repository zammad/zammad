# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Template, type: :request do
  let(:agent)    { create(:agent) }
  let(:admin)    { create(:user, roles: Role.where(name: 'Admin')) }
  let(:customer) { create(:customer) }

  describe 'request handling', authenticated_as: :admin do
    before do
      allow(ActiveSupport::Deprecation).to receive(:warn)
    end

    context 'when listing templates' do
      let!(:templates) do
        create_list(:template, 10).tap do |templates|
          templates.each do |template|

            # Make all templates with even IDs inactive (total of 5).
            template.update!(active: false) if template.id.even?
          end
        end
      end

      it 'returns all' do
        get '/api/v1/templates.json'

        expect(json_response.length).to eq(10)
      end

      it 'returns options in a new format only' do
        get '/api/v1/templates.json'

        templates.each_with_index do |template, index|
          expect(json_response[index]['options']).to eq(template.options)
        end
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'returns active templates only' do
          get '/api/v1/templates.json'

          expect(json_response.length).to eq(5)
        end
      end
    end

    context 'when showing templates' do
      let!(:template) { create(:template) }

      it 'returns ok' do
        get "/api/v1/templates/#{template.id}.json"

        expect(response).to have_http_status(:ok)
      end

      it 'returns options in a new format only' do
        get "/api/v1/templates/#{template.id}.json"

        expect(json_response['options']).to eq(template.options)
      end

      context 'with inactive template' do
        let!(:inactive_template) { create(:template, active: false) }

        it 'returns ok' do
          get "/api/v1/templates/#{inactive_template.id}.json"

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'returns ok' do
          get "/api/v1/templates/#{template.id}.json"

          expect(response).to have_http_status(:ok)
        end

        context 'with inactive template' do
          let!(:inactive_template) { create(:template, active: false) }

          it 'request is not found' do
            get "/api/v1/templates/#{inactive_template.id}.json"

            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end

    context 'when creating template' do
      it 'creates the template', :aggregate_failures do
        post '/api/v1/templates.json', params: { name: 'Foo', options: { 'ticket.title': { value: 'Bar' }, 'ticket.customer_id': { value: customer.id.to_s, value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } } }

        expect(response).to have_http_status(:created)
        expect(described_class.find_by(name: 'Foo').options).to include('ticket.title' => { 'value' => 'Bar' })
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden', :aggregate_failures do
          post '/api/v1/templates.json', params: { name: 'Foo', options: { 'ticket.title': { value: 'Bar' } } }

          expect(response).to have_http_status(:forbidden)
          expect(described_class.find_by(name: 'Foo')).to be_nil
        end
      end
    end

    context 'when updating template' do
      let!(:template) { create(:template) }

      it 'updates the template', :aggregate_failures do
        put "/api/v1/templates/#{template.id}.json", params: { options: { 'ticket.title': { value: 'Foo' } } }

        expect(response).to have_http_status(:ok)
        expect(template.reload.options).to eq('ticket.title' => { 'value' => 'Foo' })
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden', :aggregate_failures do
          expect { put "/api/v1/templates/#{template.id}.json", params: { options: { 'ticket.title': { value: 'Foo' } } } }
            .not_to change { template.reload.options }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when destroying template' do
      let!(:template) { create(:template) }

      it 'destroys the template', :aggregate_failures do
        delete "/api/v1/templates/#{template.id}.json"

        expect(response).to have_http_status(:ok)
        expect(template).not_to exist_in_database
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden', :aggregate_failures do
          delete "/api/v1/templates/#{template.id}.json"

          expect(response).to have_http_status(:forbidden)
          expect(template).to exist_in_database
        end
      end
    end
  end
end
