# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationModel::CanAssets do
  describe '.assets_of_object_list' do
    subject(:assets) { ApplicationModel.assets_of_object_list(list) }

    let(:group_with_access)    { create(:group) }
    let(:group_without_access) { create(:group) }
    let(:agent)                { create(:agent, groups: [group_with_access]) }
    let(:ticket_group)         { group_with_access }
    let(:ticket)               { create(:ticket, group: ticket_group) }

    let(:list) do
      [
        {
          'object'        => 'Ticket',
          'o_id'          => ticket.id,
          'created_by_id' => agent.id,
        }
      ]
    end

    # Set last: writing records resets the thread-local user context.
    before do
      list
      UserInfo.current_user_id = agent.id
    end

    after { UserInfo.current_user_id = nil }

    it 'ships the assets of the referenced record' do
      expect(assets[:Ticket]).to include(ticket.id => include('title' => ticket.title))
    end

    context 'when the current user has no access to the referenced record' do
      let(:ticket_group) { group_without_access }

      it 'ships no assets of the referenced record' do
        expect(assets).not_to have_key(:Ticket)
      end
    end
  end
end
