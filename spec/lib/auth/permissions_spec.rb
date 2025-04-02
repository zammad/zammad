# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::Permissions, type: :request do
  shared_examples 'verify permissions checking' do
    let(:permission)       { create(:permission, name: permission_name) }
    let(:permission_names) { [permission.name] }
    let(:role)             { create(:role, permission_names:) }

    context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
      let(:permission_name) { 'foo' }

      context 'when given that exact permission' do
        it 'returns true' do
          expect(described_class).to be_authorized(object, 'foo')
        end
      end

      context 'when given an active sub-permission' do
        before { create(:permission, name: 'foo.bar') }

        it 'returns true' do
          expect(described_class).to be_authorized(object, 'foo.bar')
        end
      end

      describe 'chain-of-ancestry quirk' do
        context 'when given an inactive sub-permission' do
          before { create(:permission, name: 'foo.bar.baz', active: false) }

          it 'returns false, even with active ancestors' do
            expect(described_class).not_to be_authorized(object, 'foo.bar.baz')
          end
        end

        context 'when given a sub-permission that does not exist' do
          before { create(:permission, name: 'foo.bar', active: false) }

          it 'can return true, even with inactive ancestors' do
            expect(described_class).to be_authorized(object, 'foo.bar.baz')
          end
        end
      end

      context 'when given a glob' do
        context 'when matching that permission' do
          it 'returns true' do
            expect(described_class).to be_authorized(object, 'foo.*')
          end
        end

        context 'when NOT matching that permission' do
          it 'returns false' do
            expect(described_class).not_to be_authorized(object, 'bar.*')
          end
        end
      end
    end

    context 'with privileges for a sub-permission (e.g., "foo.bar", not "foo")' do
      let(:permission_name) { 'foo.bar' }

      context 'when given that exact sub-permission' do
        it 'returns true' do
          expect(described_class).to be_authorized(object, 'foo.bar')
        end

        context 'when the permission is inactive' do
          before { permission.update(active: false) }

          it 'returns false' do
            expect(described_class).not_to be_authorized(object, 'foo.bar')
          end
        end
      end

      context 'when given a sibling sub-permission' do
        let(:sibling_permission) { create(:permission, name: 'foo.baz') }

        context 'when sibling exists' do
          before { sibling_permission }

          it 'returns false' do
            expect(described_class).not_to be_authorized(object, 'foo.baz')
          end
        end

        context 'when sibling does not exist' do
          it 'returns false' do
            expect(described_class).not_to be_authorized(object, 'foo.baz')
          end
        end
      end

      context 'when given the parent permission' do
        it 'returns false' do
          expect(described_class).not_to be_authorized(object, 'foo')
        end
      end

      context 'when given a glob' do
        context 'when matching that sub-permission' do
          it 'returns true' do
            expect(described_class).to be_authorized(object, 'foo.*')
          end

          context 'when the permission is inactive' do
            before { permission.update(active: false) }

            it 'returns false' do
              expect(described_class).not_to be_authorized(object, 'foo.*')
            end
          end
        end

        context 'when NOT matching that sub-permission' do
          it 'returns false' do
            expect(described_class).not_to be_authorized(object, 'bar.*')
          end
        end
      end

      context 'when given a plus' do
        let(:permission_names) { [permission.name, 'ticket.agent'] }

        context 'when matching both permissions' do
          it 'returns true' do
            expect(described_class).to be_authorized(object, 'foo.bar+ticket.agent')
          end

          it 'returns true if vice versa order given' do
            expect(described_class).to be_authorized(object, 'ticket.agent+foo.bar')
          end

          it 'returns true if given a glob' do
            expect(described_class).to be_authorized(object, 'foo.*+ticket.agent')
          end

          context 'when one of the permissions is inactive' do
            before { permission.update(active: false) }

            it 'returns false' do
              expect(described_class).not_to be_authorized(object, 'ticket.agent+foo.bar')
            end
          end
        end

        context 'when not matching one of permissions' do
          it 'returns false' do
            expect(described_class).not_to be_authorized(object, 'bar+ticket.agent')
          end

          it 'returns false if vice versa order given' do
            expect(described_class).not_to be_authorized(object, 'ticket.agent+bar')
          end
        end
      end
    end
  end

  describe 'user handling' do
    let(:object) { create(:user, roles: [role]) }

    include_examples 'verify permissions checking'
  end

  describe 'token handling' do
    let(:user)   { create(:user, roles: [role]) }
    let(:object) { create(:token, user:, preferences: { permission: permission_names }) }

    include_examples 'verify permissions checking'
  end

  describe 'caching' do
    let(:user) { create(:agent) }

    before do
      allow(described_class).to receive(:new).and_call_original
    end

    it 'caches response with same arguments' do
      described_class.authorized?(user, 'ticket.agent')
      described_class.authorized?(user, 'ticket.agent')

      expect(described_class).to have_received(:new).once
    end

    it 'does not cache response with different queries' do
      described_class.authorized?(user, 'ticket.agent')
      described_class.authorized?(user, 'other')

      expect(described_class).to have_received(:new).twice
    end

    it 'does not cache response with different objects' do
      described_class.authorized?(user, 'ticket.agent')
      described_class.authorized?(create(:user), 'ticket.agent')

      expect(described_class).to have_received(:new).twice
    end
  end
end
