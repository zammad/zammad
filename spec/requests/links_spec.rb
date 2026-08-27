# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Link', type: :request do

  describe 'GET /api/v1/links' do

    context 'when requesting links of Ticket', authenticated_as: -> { agent } do

      subject!(:ticket) { create(:ticket) }

      let(:agent) { create(:agent, groups: [ticket.group]) }

      let(:params) do
        {
          link_object:       ticket.class.name,
          link_object_value: ticket.id,
        }
      end
      let(:linked) { create(:ticket, group: ticket.group) }

      before do
        create(:link, from: ticket, to: linked)
        get '/api/v1/links', params: params, as: :json
      end

      it 'is present in response' do
        expect(response).to have_http_status(:ok)
        expect(json_response['links']).to eq([
                                               {
                                                 'link_type'         => 'normal',
                                                 'link_object'       => 'Ticket',
                                                 'link_object_value' => linked.id
                                               }
                                             ])
      end

      context 'without permission to linked Ticket Group' do
        let(:linked) { create(:ticket) }

        it 'is not present in response' do
          expect(response).to have_http_status(:ok)
          expect(json_response['links']).to be_blank
        end
      end
    end
  end

  describe 'POST /api/v1/links/add', authenticated_as: -> { agent } do
    let(:ticket) { create(:ticket) }
    let(:source) { create(:ticket, group: ticket.group) }
    let(:agent)  { create(:agent, groups: [ticket.group]) }

    let(:params) do
      {
        link_type:                 'normal',
        link_object_target:        ticket.class.name,
        link_object_target_value:  ticket.id,
        link_object_source:        source.class.name,
        link_object_source_number: source.number,
      }
    end

    let(:existing_links) { [] }

    before do
      existing_links.each { |link| create(:link, **link) }

      post '/api/v1/links/add', params: params, as: :json
    end

    it 'adds the link' do
      expect(response).to have_http_status(:created)
      expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id))
        .to include(include('link_object_value' => source.id))
    end

    context 'when the source is the target' do
      let(:source) { ticket }

      it 'responds with an error' do
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('An object cannot be linked to itself.')
      end

      it 'does not add the link' do
        expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id)).to be_blank
      end
    end

    context 'when the link already exists' do
      let(:existing_links) { [{ from: source, to: ticket }] }

      it 'responds with an error' do
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Link already exists')
      end
    end
  end
end
