# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Role do
  subject(:role) { create(:role) }

  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'

  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasGroups', group_access_factory: :role
  it_behaves_like 'HasCollectionUpdate', collection_factory: :role
  it_behaves_like 'HasXssSanitizedNote', model_factory: :role
  it_behaves_like 'Association clears cache', association: :permissions
  it_behaves_like 'Association clears cache', association: :users

  describe '#grants_elevated_access?' do
    it 'is true for a role with the agent permission' do
      expect(create(:role, :agent).grants_elevated_access?).to be(true)
    end

    it 'is true for a role with the admin permission' do
      expect(create(:role, :admin).grants_elevated_access?).to be(true)
    end

    it 'is true for a role with an admin.* sub-permission' do
      expect(create(:role, :admin_core_workflow).grants_elevated_access?).to be(true)
    end

    it 'is false for a role with only the customer permission' do
      expect(create(:role, :customer).grants_elevated_access?).to be(false)
    end
  end

  describe 'audit logging of role assignment (role side)' do
    let(:user)       { create(:user) }
    let(:audit_logs) { AuditLog.where(auditable: user) }

    before do
      Setting.set('system_init_done', true)
    end

    context 'with an agent/admin related role' do
      subject(:role) { create(:role, :agent) }

      it 'logs an update entry for the user when assigned' do
        expect { role.users << user }
          .to change { audit_logs.where(action_type: 'update').count }.by(1)
      end

      it 'records the role name in value_to' do
        role.users << user

        expect(audit_logs.find_by(action_type: 'update').value_to).to eq('roles' => [role.name])
      end

      it 'logs an update entry with value_from for the user when removed' do
        role.users << user
        role.users.delete(user)

        expect(audit_logs.reorder(:id).last).to have_attributes(
          action_type: 'update',
          value_from:  { 'roles' => [role.name] },
        )
      end
    end

    context 'with a customer role' do
      subject(:role) { create(:role, :customer) }

      it 'creates no audit log entry' do
        user
        role

        expect { role.users << user }.not_to change(AuditLog, :count)
      end
    end
  end

  describe 'audit logging of permission changes' do
    subject(:role) { create(:role) }

    let(:audit_logs)   { AuditLog.where(auditable: role) }
    let(:permission_a) { create(:permission) }
    let(:permission_b) { create(:permission) }

    # simulate a change to an existing role (assignments during role creation are not logged)
    before do
      Setting.set('system_init_done', true)
      role.reload
    end

    it 'logs an update entry when a permission is added' do
      expect { role.permissions << permission_a }
        .to change { audit_logs.where(action_type: 'update').count }.by(1)
    end

    it 'logs added and removed permissions of one update in a single entry' do
      role.permissions << permission_a

      expect { role.update!(permissions: [permission_b]) }
        .to change { audit_logs.where(action_type: 'update').count }.by(1)
    end

    it 'records added and removed permissions in value_to and value_from' do
      role.permissions << permission_a
      role.update!(permissions: [permission_b])

      expect(audit_logs.reorder(:id).last).to have_attributes(
        action_type: 'update',
        value_from:  { 'permissions' => [permission_a.name] },
        value_to:    { 'permissions' => [permission_b.name] },
      )
    end
  end

  describe 'audit logging of group permission changes' do
    subject(:role) { create(:role, :agent) }

    let(:audit_logs) { AuditLog.where(auditable: role) }
    let(:group)      { create(:group) }

    # simulate a change to an existing role (assignments during role creation are not logged)
    before do
      Setting.set('system_init_done', true)
      role.reload
      role.update!(group_names_access_map: { group.name => ['read'] })
    end

    it 'logs an update entry when the group access changes' do
      expect { role.update!(group_names_access_map: { group.name => ['full'] }) }
        .to change { audit_logs.where(action_type: 'update').count }.by(1)
    end

    it 'records removed and added access per group name under a group_permissions key' do
      role.update!(group_names_access_map: { group.name => ['full'] })

      expect(audit_logs.reorder(:id).last).to have_attributes(
        action_type: 'update',
        value_from:  { 'group_permissions' => { group.name => ['read'] } },
        value_to:    { 'group_permissions' => { group.name => ['full'] } },
      )
    end

    it 'creates no update entry when the role gets destroyed' do
      expect { role.destroy! }
        .not_to change { audit_logs.where(action_type: 'update').count }
    end
  end

  describe 'audit logging of combined role updates' do
    subject(:role) { create(:role, :agent) }

    let(:audit_logs) { AuditLog.where(auditable: role) }
    let(:group)      { create(:group) }
    let(:permission) { create(:permission) }

    before do
      Setting.set('system_init_done', true)
      role.reload
    end

    def update_role_in_one_transaction
      role.with_lock do
        role.update!(name: 'Some updated name', permissions: role.permissions + [permission], group_names_access_map: { group.name => ['full'] })
      end
    end

    it 'creates a single update entry for all changes of one transaction' do
      expect { update_role_in_one_transaction }
        .to change { audit_logs.where(action_type: 'update').count }.by(1)
    end

    it 'merges attribute, permission and group permission changes into the entry' do
      update_role_in_one_transaction

      expect(audit_logs.find_by(action_type: 'update').value_to)
        .to include('name' => 'Some updated name', 'permissions' => [permission.name], 'group_permissions' => { group.name => ['full'] })
    end

    it 'records the changed attributes including the association keys' do
      update_role_in_one_transaction

      expect(audit_logs.find_by(action_type: 'update').preferences['changed_attributes'])
        .to match_array(%w[name permissions group_permissions])
    end
  end

  describe 'audit logging of role destruction' do
    let(:group) { create(:group) }

    before do
      Setting.set('system_init_done', true)
    end

    it 'includes the permissions and group permissions in the destroy entry' do
      destroyed_role = create(:role, :agent, group_names_access_map: { group.name => ['full'] })
      destroyed_role.destroy!

      expect(AuditLog.find_by(auditable_type: 'Role', auditable_id: destroyed_role.id, action_type: 'destroy').value_from)
        .to include('permissions' => ['ticket.agent'], 'group_permissions' => { group.name => ['full'] })
    end
  end

  describe 'audit logging of role creation' do
    let(:group) { create(:group) }

    before do
      Setting.set('system_init_done', true)
    end

    it 'includes the selected permissions in the create entry' do
      new_role = create(:role, :agent)

      expect(AuditLog.find_by(auditable: new_role, action_type: 'create').value_to)
        .to include('permissions' => ['ticket.agent'])
    end

    it 'includes the selected group permissions in the create entry' do
      new_role = create(:role, :agent, group_names_access_map: { group.name => ['full'] })

      expect(AuditLog.find_by(auditable: new_role, action_type: 'create').value_to)
        .to include('group_permissions' => { group.name => ['full'] })
    end

    it 'includes no permission keys when created without permissions' do
      new_role = create(:role)

      expect(AuditLog.find_by(auditable: new_role, action_type: 'create').value_to.keys)
        .not_to include('permissions', 'group_permissions')
    end

    it 'creates no additional update entries when created with permissions and group permissions' do
      new_role = create(:role, :agent, group_names_access_map: { group.name => ['full'] })

      expect(AuditLog.where(auditable: new_role).map(&:action_type)).to eq(['create'])
    end
  end

  describe 'Default state' do
    describe 'of whole table:' do
      it 'has three records ("Admin", "Agent", and "Customer")' do
        expect(described_class.pluck(:name)).to match_array(%w[Admin Agent Customer])
      end
    end

    describe 'of "Admin" role:' do
      it 'has default admin permissions' do
        expect(described_class.find_by(name: 'Admin').permissions.pluck(:name))
          .to match_array(%w[admin user_preferences report knowledge_base.editor])
      end
    end

    describe 'of "Agent" role:' do
      it 'has default agent permissions' do
        expect(described_class.find_by(name: 'Agent').permissions.pluck(:name))
          .to match_array(%w[ticket.agent chat.agent cti.agent user_preferences knowledge_base.reader])
      end
    end

    describe 'of "Customer" role:' do
      it 'has default customer permissions' do
        expect(described_class.find_by(name: 'Customer').permissions.pluck(:name))
          .to match_array(
            %w[
              user_preferences.two_factor_authentication
              user_preferences.password
              user_preferences.language
              user_preferences.linked_accounts
              user_preferences.avatar
              user_preferences.appearance
              ticket.customer
            ]
          )
      end
    end
  end

  describe 'Callbacks -' do
    describe 'Permission validation:' do
      context 'with normal permission' do
        let(:permission) { create(:permission) }

        it 'can be created' do
          expect { create(:role, permissions: [permission]) }
            .to change(described_class, :count).by(1)
        end

        it 'can be added' do
          expect { role.permissions << permission }
            .to change { role.permissions.count }.by(1)
        end
      end

      context 'with disabled permission' do
        let(:permission) { create(:permission, preferences: { disabled: true }) }

        it 'cannot be created' do
          expect { create(:role, permissions: [permission]) }
            .to raise_error(%r{is disabled})
            .and not_change(described_class, :count)
        end

        it 'cannot be added' do
          expect { role.permissions << permission }
            .to raise_error(%r{is disabled})
            .and not_change { role.permissions.count }
        end
      end

      context 'with multiple, explicitly incompatible permissions' do
        let(:permission) { create(:permission, preferences: { not: [Permission.first.name] }) }

        it 'cannot be created' do
          expect { create(:role, permissions: [Permission.first, permission]) }
            .to raise_error(%r{conflicts with})
            .and not_change(described_class, :count)
        end

        it 'cannot be added' do
          role.permissions << Permission.first

          expect { role.permissions << permission }
            .to raise_error(%r{conflicts with})
            .and not_change { role.permissions.count }
        end
      end

      context 'with multiple, compatible permissions' do
        let(:permission) { create(:permission, preferences: { not: [Permission.pluck(:name).max.next] }) }

        it 'can be created' do
          expect { create(:role, permissions: [Permission.first, permission]) }
            .to change(described_class, :count).by(1)
        end

        it 'can be added' do
          role.permissions << Permission.first

          expect { role.permissions << permission }
            .to change { role.permissions.count }.by(1)
        end
      end
    end

    describe 'System-wide agent limit checks:' do
      let(:agents) { User.with_permissions('ticket.agent') }

      describe '#validate_agent_limit_by_attributes' do
        context 'when reactivating a role adds new agents' do
          subject(:role) { create(:role, :agent, active: false) }

          before { create(:user, roles: [role]) }

          context 'exceeding the system limit' do
            before { Setting.set('system_agent_limit', agents.count) }

            it 'fails and raises an error' do
              expect { role.update!(active: true) }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(agents, :count)
            end
          end
        end
      end
    end

    describe 'Restrictions on #default_at_signup:' do
      context 'for roles with "admin" permissions' do
        subject(:role) { build(:role, permissions: Permission.where(name: 'admin')) }

        it 'cannot be set to true on creation' do
          role.default_at_signup = true

          expect { role.save }
            .to raise_error(Exceptions::UnprocessableContent, %r{Cannot set default at signup})
        end

        it 'cannot be changed to true' do
          role.save

          expect { role.update(default_at_signup: true) }
            .to raise_error(Exceptions::UnprocessableContent, %r{Cannot set default at signup})
        end
      end

      context 'for roles with permissions that are children of "admin"' do
        subject(:role) { build(:role, permissions: [permission]) }

        let(:permission) { create(:permission, name: 'admin.foo') }

        it 'cannot be set to true on creation' do
          role.default_at_signup = true

          expect { role.save }
            .to raise_error(Exceptions::UnprocessableContent, %r{Cannot set default at signup})
        end

        it 'cannot be changed to true' do
          role.save

          expect { role.update(default_at_signup: true) }
            .to raise_error(Exceptions::UnprocessableContent, %r{Cannot set default at signup})
        end
      end

      context 'for roles with "ticket.agent" permissions' do
        subject(:role) { build(:role, permissions: Permission.where(name: 'ticket.agent')) }

        it 'cannot be set to true on creation' do
          role.default_at_signup = true

          expect { role.save }
            .to raise_error(Exceptions::UnprocessableContent, %r{Cannot set default at signup})
        end

        it 'cannot be changed to true' do
          role.save

          expect { role.update(default_at_signup: true) }
            .to raise_error(Exceptions::UnprocessableContent, %r{Cannot set default at signup})
        end
      end
    end

    describe 'Cleaning up groups when ticket.agent permission is lost' do
      let(:group) { Group.first }

      it 'creates a ticket.agent role with groups' do
        role = build(:role, :agent)
        role.role_groups.build group: group, access: 'full'
        role.save!

        expect(role.groups).to contain_exactly(group)
      end

      it 'saves non-ticket.agent role without groups' do
        role = build(:role, :admin)
        role.role_groups.build group: group, access: 'full'
        role.save!

        expect(role.groups).to be_blank
      end
    end
  end

  describe '.with_permissions' do
    context 'when given a name not matching any permissions' do
      let(:permission) { 'foo' }
      let(:result)     { [] }

      it 'returns an empty array' do
        expect(described_class.with_permissions(permission)).to match_array(result)
      end
    end

    context 'when given the name of a top-level permission' do
      let(:permission) { 'user_preferences' }
      let(:result) { described_class.where(name: %w[Admin Agent]) }

      it 'returns an array of roles with that permission' do
        expect(described_class.with_permissions(permission)).to match_array(result)
      end
    end

    context 'when given the name of a child permission' do
      let(:permission) { 'user_preferences.language' }
      let(:result) { described_class.all }

      it 'returns an array of roles with either that permission or an ancestor' do
        expect(described_class.with_permissions(permission)).to match_array(result)
      end
    end

    context 'when given the names of multiple permissions' do
      let(:permissions) { %w[ticket.agent ticket.customer] }
      let(:result) { described_class.where(name: %w[Agent Customer]) }

      it 'returns an array of roles matching ANY given permission' do
        expect(described_class.with_permissions(permissions)).to match_array(result)
      end
    end
  end

  describe '#with_permission?' do
    subject(:role) { described_class.find_by(name: 'Admin') }

    context 'when given the name of a permission it has' do
      it 'returns true' do
        expect(role.with_permission?('admin')).to be(true)
      end
    end

    context 'when given the name of a permission it does NOT have' do
      it 'returns false' do
        expect(role.with_permission?('ticket.customer')).to be(false)
      end
    end

    context 'when given the name of multiple permissions' do
      it 'returns true as long as ANY match' do
        expect(role.with_permission?(['admin', 'ticket.customer'])).to be(true)
      end
    end
  end

  # https://github.com/zammad/zammad/issues/5123
  describe 'Removing KB editor permission with existing KB' do
    it 'allows to remove editor but keep reader permission' do
      role = create(:role, permission_names: %w[knowledge_base.reader knowledge_base.editor])

      kb_permission = create(:knowledge_base_permission, role: role)

      role.permission_revoke('knowledge_base.editor')

      expect(kb_permission.reload).to have_attributes(access: 'reader')
    end
  end
end
