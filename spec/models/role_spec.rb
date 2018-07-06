require 'rails_helper'
require 'models/concerns/has_groups_examples'

RSpec.describe Role do
  let(:group_access_instance) { create(:role) }
  let(:new_group_access_instance) { build(:role) }

  include_examples 'HasGroups'

  context '#validate_agent_limit_by_attributes' do

    context 'agent creation limit surpassing prevention' do

      def current_agent_count
        User.with_permissions('ticket.agent').count
      end

      it 'prevents re-activation of Role with agent permission' do
        Setting.set('system_agent_limit', current_agent_count)

        inactive_agent_role = create(:role,
                                     active:      false,
                                     permissions: Permission.where(name: 'ticket.agent'))

        create(:user, roles: [inactive_agent_role])

        initial_agent_count = current_agent_count

        expect do
          inactive_agent_role.update!(active: true)
        end.to raise_error(Exceptions::UnprocessableEntity)

        expect(current_agent_count).to eq(initial_agent_count)
      end
    end
  end
end
