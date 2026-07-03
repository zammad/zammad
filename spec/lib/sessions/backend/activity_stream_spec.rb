# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Backend::ActivityStream do
  context 'when async processes affect associated objects / DB records (#2066)' do
    subject(:activity_stream) { described_class.new(user, {}) }

    let(:user)               { create(:agent, groups: [group]) }
    let(:group)              { Group.find_by(name: 'Users') }
    let(:associated_tickets) { create_list(:ticket, ticket_count, group: group) }
    let(:ticket_count)       { 20 }

    before do
      Setting.set('system_init_done', true)

      # these records must be created before the example begins
      # (same as `let!`, but harder to miss)
      associated_tickets
    end

    it 'manages race condition' do
      thread = Thread.new { associated_tickets.each(&:destroy) }
      expect { activity_stream.load }.not_to raise_error
      thread.join
    end
  end

  describe '#push' do
    subject(:activity_stream) { described_class.new(agent, {}, false, '123-1', 3) }

    let(:agent) do
      User.create_or_update(
        login:         'activity-stream-agent-1',
        firstname:     'Session',
        lastname:      "activity stream #{SecureRandom.uuid}",
        email:         'activity-stream-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         Role.where(name: %w[Agent Admin]),
        groups:        Group.all,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    before do
      Setting.set('system_init_done', true)
    end

    it 'only pushes again once the TTL elapsed and new activity exists', :aggregate_failures do
      # create min. one activity record
      Group.create_or_update(
        name:          "Random:#{SecureRandom.uuid}",
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(activity_stream.push).to be_present
      travel 1.second

      # next check should be empty
      expect(activity_stream.push).to be_blank

      # next check should be empty
      travel 4.seconds
      expect(activity_stream.push).to be_blank

      agent.update!(email: 'activity-stream-agent11@example.com')
      Ticket.create!(
        title:         '12323',
        group_id:      1,
        priority_id:   1,
        state_id:      1,
        customer_id:   1,
        updated_by_id: 1,
        created_by_id: 1,
      )

      travel 4.seconds

      # get as stream
      expect(activity_stream.push).to be_present
    end
  end
end
