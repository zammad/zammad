# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::Permissions, type: :model do
  describe '#permissions' do
    let(:user)        { create(:agent).tap { |u| u.roles = [u.roles.first] } }
    let(:role)        { user.roles.first }
    let(:permissions) { role.permissions }

    it 'is a simple association getter' do
      expect(user.permissions).to match_array(permissions)
    end

    context 'when inactive permissions' do
      before { permissions.first.update(active: false) }

      it 'omits them from the returned hash' do
        expect(user.permissions).not_to include(permissions.first)
      end
    end

    context 'when permissions on inactive roles' do
      before { role.update(active: false) }

      it 'omits them from the returned hash' do
        expect(user.permissions).not_to include(*role.permissions)
      end
    end
  end

  describe '#permissions?' do
    let(:user) { create(:agent) }

    it 'returns value from Auth::Permissions' do
      allow(Auth::Permissions).to receive(:authorized?).and_return(true)
      user.permissions?('ticket.agent')
      expect(Auth::Permissions).to have_received(:authorized?).with(user, 'ticket.agent')
    end

    it 'returns false if user does not have permission' do
      expect(user).not_to be_permissions('foo')
    end

    it 'returns true if user has permission' do
      expect(user).to be_permissions('ticket.agent')
    end
  end

  describe '#permissions!' do
    let(:user) { create(:agent) }

    it 'raises error if user does not have permission' do
      expect { user.permissions!('foo') }.to raise_error('User authorization failed.')
    end

    it 'returns true if user has permission' do
      expect(user).to be_permissions('ticket.agent')
    end
  end

  describe '#permissions_with_child_ids' do
    context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
      subject(:user) { create(:user, roles: [role]) }

      let(:role)                       { create(:role, permissions: [permission]) }
      let!(:permission)                { create(:permission, name: 'foo') }
      let!(:child_permission)          { create(:permission, name: 'foo.bar') }
      let!(:inactive_child_permission) { create(:permission, name: 'foo.baz', active: false) }

      it 'includes the IDs of user’s explicit permissions' do
        expect(user.permissions_with_child_ids)
          .to include(permission.id)
      end

      it 'includes the IDs of user’s active sub-permissions' do
        expect(user.permissions_with_child_ids)
          .to include(child_permission.id)
          .and not_include(inactive_child_permission.id)
      end
    end
  end

  describe '#permissions_with_child_names' do
    context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
      subject(:user) { create(:user, roles: [role]) }

      let(:role) { create(:role, permissions: [permission]) }
      let!(:permission)                { create(:permission, name: 'foo') }
      let!(:child_permission)          { create(:permission, name: 'foo.bar') }
      let!(:inactive_child_permission) { create(:permission, name: 'foo.baz', active: false) }

      it 'includes the names of user’s explicit permissions' do
        expect(user.permissions_with_child_names)
          .to include(permission.name)
      end

      it 'includes the names of user’s active sub-permissions' do
        expect(user.permissions_with_child_names)
          .to include(child_permission.name)
          .and not_include(inactive_child_permission.name)
      end
    end
  end

  describe '#permissions_with_child_and_parent_elements' do
    let(:user) { create(:user, roles: [role]) }
    let(:role) { create(:role, permission_names: role_permission_names) }

    context 'when user has parent permission' do
      let(:role_permission_names) { %w[admin] }

      it 'returns parent and all children permissions' do
        expect(user.permissions_with_child_and_parent_elements)
          .to include(
            have_attributes(name: 'admin'),
            have_attributes(name: 'admin.user'),
            have_attributes(name: 'admin.group'),
          )
      end

      it 'does not include other permissions' do
        expect(user.permissions_with_child_and_parent_elements)
          .to all(have_attributes(name: start_with('admin')))
      end
    end

    context 'when user has child permission' do
      let(:role_permission_names) { %w[admin.user] }

      it 'returns only child permission and disabled parent permission' do
        expect(user.permissions_with_child_and_parent_elements)
          .to contain_exactly(
            have_attributes(name: 'admin.user'),
            have_attributes(name: 'admin', preferences: include(disabled: true)),
          )
      end
    end

    context 'when user has top-level deadend permission' do
      let(:role_permission_names) { %w[report] }

      it 'returns that permission only' do
        expect(user.permissions_with_child_and_parent_elements)
          .to contain_exactly(
            have_attributes(name: 'report')
          )
      end
    end
  end

  describe '.with_permissions' do
    let(:permission) { create(:permission, name: 'foo') }
    let(:role)       { create(:role, permissions: [permission]) }
    let(:user)       { create(:user, roles: [role]) }

    before { user }

    context 'when user has permission' do
      it 'is included in the list' do
        expect(User.with_permissions('foo')).to include(user)
      end

      it 'is included in the list with sub-permission if user has parent permission' do
        expect(User.with_permissions('foo.bar')).to include(user)
      end

      it 'is included in the list if extra non-existant permissions given' do
        expect(User.with_permissions('bar', 'foo')).to include(user)
      end

      it 'is included in the list if user has only one of the given permissions' do
        expect(User.with_permissions('ticket.agent', 'foo')).to include(user)
      end

      it 'is included in the list if arguments are given as an array' do
        expect(User.with_permissions(['ticket.agent', 'foo'])).to include(user)
      end

      context 'when user is not active' do
        before { user.update! active: false }

        it 'not included in the list' do
          expect(User.with_permissions('foo')).not_to include(user)
        end
      end

      context 'when permission is not active' do
        before { permission.update! active: false }

        it 'not included in the list' do
          expect(User.with_permissions('foo')).not_to include(user)
        end
      end

      context 'when role is not active' do
        before { role.update! active: false }

        it 'not included in the list' do
          expect(User.with_permissions('foo')).not_to include(user)
        end
      end
    end

    context 'when user does not have permission' do
      it 'not included in the list' do
        expect(User.with_permissions('bar')).not_to include(user)
      end
    end
  end
end
