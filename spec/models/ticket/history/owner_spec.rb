# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > History > Owner', db_strategy: :reset do # rubocop:disable RSpec/DescribeClass
  let(:group)         { create(:group, name: 'Example Group') }
  let(:ticket)        { create(:ticket, owner: agent, group: group) }
  let(:agent)         { create(:agent, firstname: 'John', lastname: 'Doe', groups: [group]) }
  let(:another_agent) { create(:agent, firstname: 'Jane', lastname: 'Smith', groups: [group]) }

  describe '#owner' do
    before do
      create(:object_manager_attribute_text, name: 'name', display: 'Example Text', object_name: 'User')
      ObjectManager::Attribute.migration_execute

      agent.update!(name: 'Dummy1')
      another_agent.update!(name: 'Dummy2')
    end

    it 'uses the fullname of the user' do
      ticket.update!(owner_id: another_agent.id)

      history = ticket.history_get.find { |h| h['type'] == 'updated' && h['attribute'] == 'owner' }

      expect(history).to include(
        'value_from' => agent.fullname,
        'value_to'   => another_agent.fullname,
      )
    end
  end
end
