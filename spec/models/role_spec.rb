# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_ticket_create_screen_impact_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Role do
  subject(:role) { create(:role) }

  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasGroups', group_access_factory: :role
  it_behaves_like 'HasCollectionUpdate', collection_factory: :role
  it_behaves_like 'HasTicketCreateScreenImpact', create_screen_factory: :role
  it_behaves_like 'HasXssSanitizedNote', model_factory: :role

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
              user_preferences.password
              user_preferences.language
              user_preferences.linked_accounts
              user_preferences.avatar
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
            .and change(described_class, :count).by(0)
        end

        it 'cannot be added' do
          expect { role.permissions << permission }
            .to raise_error(%r{is disabled})
            .and change { role.permissions.count }.by(0)
        end
      end

      context 'with multiple, explicitly incompatible permissions' do
        let(:permission) { create(:permission, preferences: { not: [Permission.first.name] }) }

        it 'cannot be created' do
          expect { create(:role, permissions: [Permission.first, permission]) }
            .to raise_error(%r{conflicts with})
            .and change(described_class, :count).by(0)
        end

        it 'cannot be added' do
          role.permissions << Permission.first

          expect { role.permissions << permission }
            .to raise_error(%r{conflicts with})
            .and change { role.permissions.count }.by(0)
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
          subject(:role) { create(:agent_role, active: false) }

          before { create(:user, roles: [role]) }

          context 'exceeding the system limit' do
            before { Setting.set('system_agent_limit', agents.count) }

            it 'fails and raises an error' do
              expect { role.update!(active: true) }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change(agents, :count).by(0)
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
            .to raise_error(Exceptions::UnprocessableEntity, %r{Cannot set default at signup})
        end

        it 'cannot be changed to true' do
          role.save

          expect { role.update(default_at_signup: true) }
            .to raise_error(Exceptions::UnprocessableEntity, %r{Cannot set default at signup})
        end
      end

      context 'for roles with permissions that are children of "admin"' do
        subject(:role) { build(:role, permissions: [permission]) }

        let(:permission) { create(:permission, name: 'admin.foo') }

        it 'cannot be set to true on creation' do
          role.default_at_signup = true

          expect { role.save }
            .to raise_error(Exceptions::UnprocessableEntity, %r{Cannot set default at signup})
        end

        it 'cannot be changed to true' do
          role.save

          expect { role.update(default_at_signup: true) }
            .to raise_error(Exceptions::UnprocessableEntity, %r{Cannot set default at signup})
        end
      end

      context 'for roles with "ticket.agent" permissions' do
        subject(:role) { build(:role, permissions: Permission.where(name: 'ticket.agent')) }

        it 'cannot be set to true on creation' do
          role.default_at_signup = true

          expect { role.save }
            .to raise_error(Exceptions::UnprocessableEntity, %r{Cannot set default at signup})
        end

        it 'cannot be changed to true' do
          role.save

          expect { role.update(default_at_signup: true) }
            .to raise_error(Exceptions::UnprocessableEntity, %r{Cannot set default at signup})
        end
      end
    end
  end

  describe '.with_permissions' do
    context 'when given a name not matching any permissions' do
      let(:permission) { 'foo' }
      let(:result) { [] }

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
end
