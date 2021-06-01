# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Token, type: :model do
  subject(:token) { create(:password_reset_token) }

  describe '.check' do
    context 'with name and action matching existing token' do
      it 'returns the token’s user' do
        expect(described_class.check(action: token.action, name: token.name)).to eq(token.user)
      end
    end

    context 'with invalid name' do
      it 'returns nil' do
        expect(described_class.check(action: token.action, name: '1NV4L1D')).to be(nil)
      end
    end

    context 'with invalid action' do
      it 'returns nil' do
        expect(described_class.check(action: 'PasswordReset_NotExisting', name: token.name)).to be(nil)
      end
    end

    describe 'persistence handling' do
      context 'for persistent token' do
        subject(:token) { create(:ical_token, persistent: true, created_at: created_at) }

        context 'at any time' do
          let(:created_at) { 1.month.ago }

          it 'returns the token’s user' do
            expect(described_class.check(action: token.action, name: token.name)).to eq(token.user)
          end

          it 'does not delete the token' do
            token  # create token

            expect { described_class.check(action: token.action, name: token.name) }
              .not_to change(described_class, :count)
          end
        end
      end

      context 'for non-persistent token' do
        subject(:token) { create(:password_reset_token, persistent: false, created_at: created_at) }

        context 'less than one day after creation' do
          let(:created_at) { 1.day.ago + 5 }

          it 'returns the token’s user' do
            expect(described_class.check(action: token.action, name: token.name)).to eq(token.user)
          end

          it 'does not delete the token' do
            token  # create token

            expect { described_class.check(action: token.action, name: token.name) }
              .not_to change(described_class, :count)
          end
        end

        context 'at least one day after creation' do
          let(:created_at) { 1.day.ago }

          it 'returns nil' do
            expect(described_class.check(action: token.action, name: token.name)).to be(nil)
          end

          it 'deletes the token' do
            token  # create token

            expect { described_class.check(action: token.action, name: token.name) }
              .to change(described_class, :count).by(-1)
          end
        end
      end
    end

    describe 'permission matching' do
      subject(:token) { create(:api_token, user: agent, preferences: preferences) }

      let(:agent) { create(:agent) }
      let(:preferences) { { permission: %w[admin ticket.agent] } } # agent has no access to admin.*

      context 'with a permission shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'ticket.agent')).to eq(agent)
        end
      end

      context 'with the child of a permission shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'ticket.agent.foo')).to eq(agent)
        end
      end

      context 'with the parent of a permission shared by both token.user and token.preferences' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'ticket')).to be(nil)
        end
      end

      context 'with a permission in token.preferences, but not on token.user' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'admin')).to be(nil)
        end
      end

      context 'with a permission not in token.preferences, but on token.user' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'cti.agent')).to be(nil)
        end
      end

      context 'with non-existent permission' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'foo')).to be(nil)
        end
      end

      context 'with multiple permissions, where at least one is shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, name: token.name, permission: %w[foo ticket.agent])).to eq(agent)
        end
      end
    end
  end

  describe '#permissions?' do
    subject(:token) do
      create(:token, user: user, preferences: { permission: [permission_name] })
    end

    let(:user) { create(:user, roles: [role]) }
    let(:role) { create(:role, permissions: [permission]) }
    let(:permission) { create(:permission, name: permission_name) }

    context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
      let(:permission_name) { 'foo' }

      context 'when given that exact permission' do
        it 'returns true' do
          expect(token.permissions?('foo')).to be(true)
        end
      end

      context 'when given a sub-permission (i.e., child permission)' do
        let(:subpermission) { create(:permission, name: 'foo.bar') }

        context 'that exists' do
          before { subpermission }

          it 'returns true' do
            expect(token.permissions?('foo.bar')).to be(true)
          end
        end

        context 'that is inactive' do
          before { subpermission.update(active: false) }

          it 'returns false' do
            expect(token.permissions?('foo.bar')).to be(false)
          end
        end

        context 'that does not exist' do
          it 'returns true' do
            expect(token.permissions?('foo.bar')).to be(true)
          end
        end
      end

      context 'when given a glob' do
        context 'matching that permission' do
          it 'returns true' do
            expect(token.permissions?('foo.*')).to be(true)
          end
        end

        context 'NOT matching that permission' do
          it 'returns false' do
            expect(token.permissions?('bar.*')).to be(false)
          end
        end
      end
    end

    context 'with privileges for a sub-permission (e.g., "foo.bar", not "foo")' do
      let(:permission_name) { 'foo.bar' }

      context 'when given that exact sub-permission' do
        it 'returns true' do
          expect(token.permissions?('foo.bar')).to be(true)
        end

        context 'but the permission is inactive' do
          before { permission.update(active: false) }

          it 'returns false' do
            expect(token.permissions?('foo.bar')).to be(false)
          end
        end
      end

      context 'when given a sibling sub-permission' do
        let(:sibling_permission) { create(:permission, name: 'foo.baz') }

        context 'that exists' do
          before { sibling_permission }

          it 'returns false' do
            expect(token.permissions?('foo.baz')).to be(false)
          end
        end

        context 'that does not exist' do
          it 'returns false' do
            expect(token.permissions?('foo.baz')).to be(false)
          end
        end
      end

      context 'when given the parent permission' do
        it 'returns false' do
          expect(token.permissions?('foo')).to be(false)
        end
      end

      context 'when given a glob' do
        context 'matching that sub-permission' do
          it 'returns true' do
            expect(token.permissions?('foo.*')).to be(true)
          end

          context 'but the permission is inactive' do
            before { permission.update(active: false) }

            context 'and user.permissions?(...) doesn’t fail' do
              let(:role) { create(:role, permissions: [parent_permission]) }
              let(:parent_permission) { create(:permission, name: permission_name.split('.').first) }

              it 'returns false' do
                expect(token.permissions?('foo.*')).to be(false)
              end
            end
          end
        end

        context 'NOT matching that sub-permission' do
          it 'returns false' do
            expect(token.permissions?('bar.*')).to be(false)
          end
        end
      end
    end
  end

  describe 'Attributes:' do
    describe '#persistent' do
      context 'when not set on creation' do
        subject(:token) { described_class.create(action: 'foo', user_id: User.first.id) }

        it 'defaults to nil' do
          expect(token.persistent).to be(nil)
        end
      end
    end
  end
end
