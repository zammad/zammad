# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'PublicLinks', type: :request do

  let(:admin) { create(:admin) }
  let(:agent) { create(:agent, password: 'dummy') }
  let(:link)  { link_list[:first] }

  let(:link_list) do
    first_link  = create(:public_link, prio: 1)
    second_link = create(:public_link, prio: 2)
    third_link  = create(:public_link, prio: 3)

    {
      first:  first_link,
      second: second_link,
      third:  third_link,
    }
  end

  let(:create_params) do
    {
      link:        'https://zammad.org',
      title:       'Zammad <3',
      description: 'Zammad is a very cool application',
      screen:      ['login'],
      prio:        1,
    }
  end

  let(:update_params) { create_params.merge(id: link.id, title: 'Zammad Community',) }

  let(:prio_params) do
    {
      prios: [
        [ link_list[:third].id,  1 ],
        [ link_list[:second].id, 2 ],
        [ link_list[:first].id,  3 ],
      ]
    }
  end

  describe 'request handling' do
    it 'does create a new public link', :aggregate_failures do
      authenticated_as(admin)
      post '/api/v1/public_links', params: create_params, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('link' => 'https://zammad.org', 'title' => 'Zammad <3')
    end

    it 'supports setting prios', :aggregate_failures do
      authenticated_as(admin)
      post '/api/v1/public_links_prio', params: prio_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('success' => true)

      expect(link_list[:first].reload.prio).to eq(3)
      expect(link_list[:second].reload.prio).to eq(2)
      expect(link_list[:third].reload.prio).to eq(1)
    end

    it 'updates an existing link', :aggregate_failures do
      authenticated_as(admin)
      put "/api/v1/public_links/#{link.id}", params: update_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('title' => 'Zammad Community')
    end

    it 'deletes an existing link', :aggregate_failures do
      authenticated_as(admin)
      delete "/api/v1/public_links/#{link.id}", params: {}, as: :json

      expect(response).to have_http_status(:ok)
      expect(PublicLink).not_to exist(link.id)
    end
  end
end
