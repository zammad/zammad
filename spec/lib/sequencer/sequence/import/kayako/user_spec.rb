# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'lib/sequencer/sequence/import/kayako/examples/object_custom_field_values_examples'

RSpec.describe Sequencer::Sequence::Import::Kayako::User, db_strategy: :reset, sequencer: :sequence do
  context 'when importing users from Kayako' do
    let(:groups) do
      create_list(:group, 2)
    end

    let(:organization) { create(:organization) }

    let(:resource) do
      {
        'id'                   => 80_000_602_705,
        'uuid'                 => 'd4c85a6c-465f-5577-8240-276c0c7fe546',
        'full_name'            => 'John Doe',
        'is_enabled'           => true,
        'role'                 => {
          'id'                => 2,
          'title'             => 'Agent',
          'type'              => 'AGENT',
          'is_system'         => true,
          'agent_case_access' => 'ALL',
          'created_at'        => '2021-08-12T11:48:45+00:00',
          'updated_at'        => '2021-08-12T11:48:45+00:00',
          'resource_type'     => 'role',
        },
        'agent_case_access'    => 'INHERIT-FROM-ROLE',
        'organization'         => {
          'id'            => 1001,
          'resource_type' => 'user'
        },
        'teams'                => [
          {
            'id'            => 1001,
            'resource_type' => 'team',
          },
          {
            'id'            => 1002,
            'resource_type' => 'team',
          }
        ],
        'emails'               => [
          {
            'id'                      => 8,
            'email'                   => 'kayako@example.com',
            'is_primary'              => true,
            'is_validated'            => false,
            'is_notification_enabled' => false,
            'created_at'              => '2021-08-19T08:24:50+00:00',
            'updated_at'              => '2021-08-19T08:24:50+00:00',
            'resource_type'           => 'identity_email',
          },
        ],
        'phones'               => [
          {
            'id'            => 2,
            'number'        => '+49123456789',
            'is_primary'    => true,
            'is_validated'  => false,
            'created_at'    => '2021-08-19T10:16:26+00:00',
            'updated_at'    => '2021-08-19T10:16:33+00:00',
            'resource_type' => 'identity_phone',
          }
        ],
        'twitter'              => [],
        'facebook'             => [],
        'time_zone'            => nil,
        'time_zone_offset'     => nil,
        'last_seen_user_agent' => nil,
        'last_seen_ip'         => nil,
        'last_seen_at'         => nil,
        'last_active_at'       => '2021-08-19T13:16:23+00:00',
        'avatar_updated_at'    => nil,
        'last_logged_in_at'    => '2021-08-19T13:16:23+00:00',
        'last_activity_at'     => nil,
        'created_at'           => '2021-08-16T09:01:14+00:00',
        'updated_at'           => '2021-08-18T20:37:52+00:00',
        'resource_type'        => 'user',
      }
    end

    let(:id_map) do
      {
        'Group'        => {
          1001 => groups[0].id,
          1002 => groups[1].id,
        },
        'Organization' => {
          1001 => organization.id,
        },
      }
    end

    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:          false,
        resource:         resource,
        field_map:        {},
        id_map:           id_map,
        default_language: 'en-us',
      }
    end

    let(:imported_user) do
      {
        firstname:  'John',
        lastname:   'Doe',
        login:      'kayako@example.com',
        email:      'kayako@example.com',
        phone:      '+49123456789',
        active:     true,
        last_login: DateTime.parse('2021-08-19T13:16:23+00:00'),
      }
    end

    it 'increased user count' do
      expect { process(process_payload) }.to change(User, :count).by(1)
    end

    it 'adds correct user data' do
      process(process_payload)
      expect(User.last).to have_attributes(imported_user)
    end

    it 'sets user roles correctly for initiator user' do
      Setting.set('import_kayako_endpoint_username', 'kayako@example.com')
      process(process_payload)
      expect(User.last.roles.sort.map(&:name)).to eq %w[Admin Agent]
    end

    it 'sets user roles correctly for non-admin user' do
      process(process_payload)
      expect(User.last.roles.sort.map(&:name)).to eq ['Agent']
    end

    it 'sets user groups correctly' do
      process(process_payload)
      expect(User.last.groups_access('full').sort).to eq groups
    end

    context 'when importing custom fields' do
      include_examples 'Object custom field values', object_name: 'User', klass: User
    end
  end
end
