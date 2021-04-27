# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
end
