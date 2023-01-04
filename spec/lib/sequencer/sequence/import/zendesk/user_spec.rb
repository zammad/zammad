# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::User, db_strategy: :reset, sequencer: :sequence do

  context 'when importing users from Zendesk' do

    let(:groups) do
      create_list(:group, 3)
    end

    let(:merge_resource) do
      {}
    end

    let(:resource) do
      ZendeskAPI::User.new(
        nil,
        {
          'id'                      => 1_150_734_731,
          'name'                    => 'Bob Smith',
          'email'                   => 'zendesk-user@example.com',
          'created_at'              => '2015-07-19 22:41:41 UTC',
          'updated_at'              => '2021-08-19 13:40:25 UTC',
          'time_zone'               => 'Berlin',
          'iana_time_zone'          => 'Europe/Berlin',
          'phone'                   => '00114124',
          'shared_phone_number'     => true,
          'photo'                   => nil,
          'locale_id'               => 1,
          'locale'                  => 'en-US',
          'organization_id'         => 154_755_561,
          'role'                    => 'admin',
          'verified'                => true,
          'external_id'             => nil,
          'tags'                    => ['2'],
          'alias'                   => '',
          'active'                  => true,
          'shared'                  => false,
          'shared_agent'            => false,
          'last_login_at'           => '2021-08-19 13:40:25 UTC',
          'two_factor_auth_enabled' => false,
          'signature'               => '',
          'details'                 => '',
          'notes'                   => '',
          'role_type'               => nil,
          'custom_role_id'          => nil,
          'moderator'               => true,
          'ticket_restriction'      => nil,
          'only_private_comments'   => false,
          'restricted_agent'        => false,
          'suspended'               => false,
          'default_group_id'        => 1002,
          'report_csv'              => true,
          'user_fields'             => {
            'custom_dropdown' => '2',
            'lieblingstier'   => 'Hundä',
            'test::example'   => '1',
          }
        }.merge(merge_resource)
      )
    end

    let(:group_map) do
      {
        1001 => groups[0].id,
        1002 => groups[1].id,
        1003 => groups[2].id,
      }
    end

    let(:user_group_map) do
      {
        1_150_734_731 => [1001, 1002, 1003]
      }
    end

    let(:organization_map) do
      {}
    end

    let(:field_map) do
      {
        'User' => {
          'custom_dropdown' => 'custom_dropdown',
          'lieblingstier'   => 'lieblingstier',
          'test::example'   => 'test_example',
        }
      }
    end

    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:          false,
        resource:         resource,
        group_map:        group_map,
        user_group_map:   user_group_map,
        organization_map: organization_map,
        field_map:        field_map
      }
    end

    let(:merge_imported_user) { {} }

    let(:imported_user) do
      {
        firstname:       'Bob',
        lastname:        'Smith',
        login:           'zendesk-user@example.com',
        email:           'zendesk-user@example.com',
        active:          true,
        last_login:      DateTime.parse('2021-08-19T13:40:25Z'),
        custom_dropdown: '2',
        lieblingstier:   'Hundä',
        test_example:    '1',
      }.merge(merge_imported_user)
    end

    before do
      create(:object_manager_attribute_select, object_name: 'User', name: 'custom_dropdown')
      create(:object_manager_attribute_text, object_name: 'User', name: 'lieblingstier')
      create(:object_manager_attribute_text, object_name: 'User', name: 'test_example')
      ObjectManager::Attribute.migration_execute
    end

    context 'with admin user' do

      it 'imports user correctly (increased user count)' do
        expect { process(process_payload) }.to change(User, :count).by(1)
      end

      it 'imports user data correctly' do
        process(process_payload)
        expect(User.last).to have_attributes(imported_user)
      end

      it 'sets user roles correctly for admin user' do
        process(process_payload)
        expect(User.last.roles.sort.map(&:name)).to eq %w[Admin Agent]
      end
    end

    context 'with agent user' do

      let(:merge_resource) do
        {
          'role'             => 'agent',
          'restricted_agent' => true,
        }
      end

      it 'sets user roles correctly for non-admin user' do
        process(process_payload)
        expect(User.last.roles.sort.map(&:name)).to eq ['Agent']
      end

      it 'sets user groups correctly' do
        process(process_payload)
        expect(User.last.groups_access('full').sort).to eq groups
      end
    end

    context 'with inactive user' do
      let(:merge_resource) do
        {
          'active' => false,
        }
      end

      let(:merge_imported_user) do
        {
          active: false,
        }
      end

      it 'imports user data correctly' do
        process(process_payload)
        expect(User.last).to have_attributes(imported_user)
      end
    end

    context 'with suspended user' do
      let(:merge_resource) do
        {
          'suspended' => true,
        }
      end

      let(:merge_imported_user) do
        {
          active: false,
        }
      end

      it 'imports user data correctly' do
        process(process_payload)
        expect(User.last).to have_attributes(imported_user)
      end
    end
  end
end
