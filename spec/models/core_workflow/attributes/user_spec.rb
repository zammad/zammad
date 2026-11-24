# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CoreWorkflow::Attributes::User, type: :model do
  let(:group)       { create(:group) }
  let(:action_user) { create(:agent, groups: [group]) }
  let(:role_agent)  { create(:agent, roles: [create(:role, :agent, group_names_access_map: { group.name => ['full'] })]) }
  let(:payload) do
    {
      'event'      => 'core_workflow',
      'request_id' => 'ChecksCoreWorkflow.validate_workflows',
      'class_name' => 'Ticket',
      'screen'     => 'edit',
      'params'     => { 'group_id' => group.id },
    }
  end

  def owner_list(assets:)
    attributes = CoreWorkflow::Attributes.new(result_object: CoreWorkflow::Result.new(payload:, user: action_user, assets:))

    described_class.new(attributes:, attribute: { name: 'owner_id' })
  end

  before do
    role_agent
    create(:agent, groups: [group], active: false)
    create(:agent, groups: [create(:group)])
  end

  describe '#values of the ticket owner' do
    it 'lists the system user and the active agents of the group with assets' do
      expect(owner_list(assets: {}).values).to contain_exactly(1, action_user.id, role_agent.id)
    end

    context 'without assets' do
      let(:owners) { owner_list(assets: false) }

      it 'lists the same owners as with assets' do
        expect(owners.values).to contain_exactly(1, action_user.id, role_agent.id)
      end

      it 'does not instantiate the users' do
        owners
        instantiated = []
        callback     = ->(*, event_payload) { instantiated << event_payload[:class_name] }

        ActiveSupport::Notifications.subscribed(callback, 'instantiation.active_record') { owners.values }

        expect(instantiated).not_to include('User')
      end
    end
  end
end
