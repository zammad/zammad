# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      it 'returns created' do
        post '/api/v1/templates.json', params: { name: 'Foo', options: { 'ticket.title': { value: 'Bar' }, 'ticket.customer_id': { value: customer.id.to_s, value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } } }

        expect(response).to have_http_status(:created)
      end

      it 'supports template options in an older format' do
        params = { name: 'Foo', options: { title: 'Bar', customer_id: customer.id.to_s, customer_id_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } }

        post '/api/v1/templates.json', params: params

        expect(json_response['options']).to eq({ 'ticket.title': { value: 'Bar' }, 'ticket.customer_id': { value: customer.id.to_s, value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } }.deep_stringify_keys)
      end

      it 'throws deprecation warning' do
        post '/api/v1/templates.json', params: { name: 'Foo', options: { title: 'Bar', customer_id: customer.id.to_s, customer_id_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } }

        expect(ActiveSupport::Deprecation).to have_received(:warn)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          post '/api/v1/templates.json', params: { name: 'Foo', options: { 'ticket.title': { value: 'Bar' } } }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when updating template' do
      let!(:template) { create(:template) }

      it 'returns ok' do
        put "/api/v1/templates/#{template.id}.json", params: { options: { 'ticket.title': { value: 'Foo' } } }

        expect(response).to have_http_status(:ok)
      end

      it 'supports template options in an older format' do
        params = { name: 'Foo', options: { title: 'Bar', customer_id: customer.id.to_s, customer_id_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } }

        put "/api/v1/templates/#{template.id}.json", params: params

        expect(json_response['options']).to eq({ 'ticket.title': { value: 'Bar' }, 'ticket.customer_id': { value: customer.id.to_s, value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } }.deep_stringify_keys)
      end

      it 'throws deprecation warning' do
        put "/api/v1/templates/#{template.id}.json", params: { name: 'Foo', options: { title: 'Bar', customer_id: customer.id.to_s, customer_id_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" } }

        expect(ActiveSupport::Deprecation).to have_received(:warn)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          put "/api/v1/templates/#{template.id}.json", params: { options: { 'ticket.title': { value: 'Foo' } } }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when destroying template' do
      let!(:template) { create(:template) }

      it 'returns ok' do
        delete "/api/v1/templates/#{template.id}.json"

        expect(response).to have_http_status(:ok)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          delete "/api/v1/templates/#{template.id}.json"

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
