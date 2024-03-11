# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Tags', type: :request do
  let(:agent)    { create(:agent, groups: Group.all) }
  let(:customer) { create(:customer) }

  context 'when a comma-separated list of tags is provided', :aggregate_failures, authenticated_as: :agent do
    before do
      Setting.set('tag_new', false)

      %w[tag1 tag2 tag3].each do |tag|
        tag_item = create(:'tag/item', name: tag)
        create(:tag, o: Ticket.first, tag_item: tag_item)
      end
    end

    it 'creates the ticket with the correct tags' do
      params = {
        title:       'A new ticket',
        group:       Group.first.name,
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        tags:        'tag1, tag2, tag3',
      }

      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(Ticket.last.tag_list).to eq(%w[tag1 tag2 tag3])
    end
  end
end
