# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Ldap::Users, sequencer: :sequence do

  context 'lost group assignment' do

    context 'config "unassigned_users": "skip_sync"' do

      it 'disables user', last_admin_check: false do

        user_entry                   = build(:ldap_entry)
        user_entry['objectguid']     = ['user1337']
        user_entry['samaccountname'] = ['login123']
        user_entry['first_name']     = ['Hans']

        group_entry           = build(:ldap_entry)
        group_entry['member'] = [user_entry.dn]

        payload = {
          ldap_config: {
            user_filter:      'user=filter',
            group_role_map:   {
              group_entry.dn => [1, 2]
            },
            user_attributes:  {
              'samaccountname' => 'login',
              'first_name'     => 'firstname',
            },
            user_uid:         'objectguid',
            unassigned_users: 'skip_sync',
          }
        }

        import_job = build_stubbed(:import_job, name: 'Import::Ldap', payload: payload)

        connection = double(
          host:    'example.com',
          port:    1337,
          ssl:     true,
          base_dn: 'test'
        )

        # LDAP::Group
        allow(connection).to receive(:search).and_yield(group_entry)
        allow(connection).to receive(:entries?).and_return(true)

        # Sequencer::Unit::Import::Ldap::Users::Total
        allow(connection).to receive(:count).and_return(1)

        # Sequencer::Unit::Import::Ldap::Users::SubSequence
        allow(connection).to receive(:search).and_yield(user_entry)

        expect do
          process(
            ldap_connection: connection,
            import_job:      import_job,
          )
        end.to change(User, :count).by(1)

        imported_user = User.last

        expect(imported_user.active).to be true

        connection = double(
          host:    'example.com',
          port:    1337,
          ssl:     true,
          base_dn: 'test'
        )

        group_entry['member'] = ['some.other.dn']

        # LDAP::Group
        allow(connection).to receive(:search).and_yield(group_entry)
        allow(connection).to receive(:entries?).and_return(true)

        expect do
          process(
            ldap_connection: connection,
            import_job:      import_job,
          )
        end.not_to change(User, :count)

        imported_user.reload

        expect(imported_user.active).to be false
      end
    end

    context 'config "unassigned_users": nil / "sigup_roles"' do

      it 'assigns signup roles', last_admin_check: false do

        user_entry                   = build(:ldap_entry)
        user_entry['objectguid']     = ['user1337']
        user_entry['samaccountname'] = ['login123']
        user_entry['first_name']     = ['Hans']

        group_entry           = build(:ldap_entry)
        group_entry['member'] = [user_entry.dn]

        agent_admin_role_ids = [1, 2]

        payload = {
          ldap_config: {
            user_filter:     'user=filter',
            group_role_map:  {
              group_entry.dn => agent_admin_role_ids
            },
            user_attributes: {
              'samaccountname' => 'login',
              'first_name'     => 'firstname',
            },
            user_uid:        'objectguid',
          }
        }

        import_job = build_stubbed(:import_job, name: 'Import::Ldap', payload: payload)

        connection = double(
          host:    'example.com',
          port:    1337,
          ssl:     true,
          base_dn: 'test'
        )

        # LDAP::Group and Sequencer::Unit::Import::Ldap::Users::SubSequence
        allow(connection).to receive(:search).and_yield(group_entry).and_yield(user_entry)
        allow(connection).to receive(:entries?).and_return(true)

        # Sequencer::Unit::Import::Ldap::Users::Total
        allow(connection).to receive(:count).and_return(1)

        expect do
          process(
            ldap_connection: connection,
            import_job:      import_job,
          )
        end.to change(User, :count).by(1)

        imported_user = User.last

        expect(imported_user.role_ids).to eq(agent_admin_role_ids)

        connection = double(
          host:    'example.com',
          port:    1337,
          ssl:     true,
          base_dn: 'test'
        )

        group_entry['member'] = ['some.other.dn']

        # LDAP::Group
        allow(connection).to receive(:search).and_yield(group_entry)
        allow(connection).to receive(:entries?).and_return(true)

        # Sequencer::Unit::Import::Ldap::Users::Total
        # cached
        # expect(connection).to receive(:count).and_return(1)

        # Sequencer::Unit::Import::Ldap::Users::SubSequence
        allow(connection).to receive(:search).and_yield(user_entry)

        expect do
          process(
            ldap_connection: connection,
            import_job:      import_job,
          )
        end.not_to change(User, :count)

        imported_user.reload

        expect(imported_user.roles).to eq(Role.signup_roles)
      end
    end
  end
end
