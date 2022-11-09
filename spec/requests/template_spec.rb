# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Template, type: :request do
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }

  describe 'request handling', authenticated_as: :agent do
    before do
      allow(ActiveSupport::Deprecation).to receive(:warn)
    end

    context 'when listing templates' do
      let!(:templates) { create_list(:template, 10) }

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
    end

    context 'when destroying template' do
      let!(:template) { create(:template) }

      it 'returns ok' do
        delete "/api/v1/templates/#{template.id}.json"

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
