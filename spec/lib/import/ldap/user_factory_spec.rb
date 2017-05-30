require 'rails_helper'

RSpec.describe Import::Ldap::UserFactory do

  describe '.import' do

    it 'responds to .import' do
      expect(described_class).to respond_to(:import)
    end

    it 'imports users matching the configured filter' do

      config = {
        user_filter:     '(objectClass=user)',
        group_filter:    '(objectClass=group)',
        user_uid:        'uid',
        user_attributes: {
          'uid'   => 'login',
          'email' => 'email',
        }
      }

      mocked_entry = build(:ldap_entry)

      mocked_entry['uid']   = ['exampleuid']
      mocked_entry['email'] = ['example@example.com']

      mocked_ldap = double(
        host:    'ldap.example.com',
        port:    636,
        ssl:     true,
        base_dn: 'dc=example,dc=com'
      )

      # group user role mapping
      expect(mocked_ldap).to receive(:search)
      # user counting
      allow(mocked_ldap).to receive(:count).and_return(1)
      # user search
      expect(mocked_ldap).to receive(:search).and_yield(mocked_entry)

      expect do
        described_class.import(
          config: config,
          ldap:   mocked_ldap
        )
      end.to change {
        User.count
      }.by(1)
    end

    it 'supports dry run' do

      config = {
        user_filter:     '(objectClass=user)',
        group_filter:    '(objectClass=group)',
        user_uid:        'uid',
        user_attributes: {
          'uid'   => 'login',
          'email' => 'email',
        }
      }

      mocked_entry = build(:ldap_entry)

      mocked_entry['uid']   = ['exampleuid']
      mocked_entry['email'] = ['example@example.com']

      mocked_ldap = double(
        host:    'ldap.example.com',
        port:    636,
        ssl:     true,
        base_dn: 'dc=example,dc=com'
      )

      # group user role mapping
      expect(mocked_ldap).to receive(:search)
      # user counting
      expect(mocked_ldap).to receive(:count).and_return(1)
      # user search
      expect(mocked_ldap).to receive(:search).and_yield(mocked_entry)

      expect do
        described_class.import(
          config:  config,
          ldap:    mocked_ldap,
          dry_run: true
        )
      end.not_to change {
        User.count
      }
    end
  end

  describe '.add_to_statistics' do

    it 'responds to .add_to_statistics' do
      expect(described_class).to respond_to(:add_to_statistics)
    end

    it 'adds statistics per user role' do

      mocked_backend_instance = double(
        action:   :created,
        resource: double(
          role_ids: [1, 2]
        )
      )

      # initialize empty statistic
      described_class.reset_statistics

      described_class.add_to_statistics(mocked_backend_instance)

      expected = {
        role_ids: {
          1 => {
            created:   1,
            updated:   0,
            unchanged: 0,
            failed:    0
          },
          2 => {
            created:   1,
            updated:   0,
            unchanged: 0,
            failed:    0
          },
        },
        skipped:   0,
        created:   1,
        updated:   0,
        unchanged: 0,
        failed:    0,
      }

      expect(described_class.statistics).to include(expected)
    end

    it 'skips not created instances' do

      mocked_backend_instance = double(
        action:   :skipped,
        resource: nil,
      )

      # initialize empty statistic
      described_class.reset_statistics

      described_class.add_to_statistics(mocked_backend_instance)

      expected = {
        skipped:   1,
        created:   0,
        updated:   0,
        unchanged: 0,
        failed:    0,
      }

      expect(described_class.statistics).to include(expected)
    end

    it 'skips unwanted actions instances' do

      mocked_backend_instance = double(
        action:   :skipped,
        resource: double(
          role_ids: [1, 2]
        )
      )

      # initialize empty statistic
      described_class.reset_statistics

      described_class.add_to_statistics(mocked_backend_instance)

      expected = {
        skipped:   1,
        created:   0,
        updated:   0,
        unchanged: 0,
        failed:    0,
      }

      expect(described_class.statistics).to include(expected)
    end

  end

  describe '.user_roles' do

    it 'responds to .user_roles' do
      expect(described_class).to respond_to(:user_roles)
    end

    it 'fetches the user DN to local role mapping' do

      group_dn = 'dn=... admin group...'
      user_dn  = 'dn=... admin user...'

      config = {
        group_filter:   '(objectClass=group)',
        group_role_map: {
          group_dn => %w(1 2),
        }
      }

      mocked_entry = build(:ldap_entry)

      mocked_entry['dn']     = group_dn
      mocked_entry['member'] = [user_dn]

      mocked_ldap = double()
      expect(mocked_ldap).to receive(:search).and_yield(mocked_entry)

      user_roles = described_class.user_roles(
        ldap:   mocked_ldap,
        config: config,
      )

      expected = {
        user_dn => [1, 2]
      }

      expect(user_roles).to be_a(Hash)
      expect(user_roles).to eq(expected)
    end
  end
end
