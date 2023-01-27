# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::Agent, sequencer: :sequence do

  context 'when importing agents from Freshdesk' do

    let(:groups) do
      create_list(:group, 3)
    end

    let(:resource) do
      {
        'available'       => false,
        'occasional'      => false,
        'id'              => 1001,
        'ticket_scope'    => 1,
        'created_at'      => '2021-04-09T13:23:58Z',
        'updated_at'      => '2021-05-10T09:14:20Z',
        'last_active_at'  => '2021-05-10T09:14:20Z',
        'available_since' => nil,
        'type'            => 'support_agent',
        'contact'         => {
          'active'        => false,
          'email'         => 'freshdesk@example.com',
          'job_title'     => nil,
          'language'      => 'en',
          'last_login_at' => '2021-05-10T07:52:58Z',
          'mobile'        => nil,
          'name'          => 'John Doe',
          'phone'         => nil,
          'time_zone'     => 'Eastern Time (US & Canada)',
          'created_at'    => '2021-04-09T13:23:58Z',
          'updated_at'    => '2021-04-09T13:31:00Z'
        },
        'signature'       => nil,
        'group_ids'       => [1001, 1002, 1003]
      }
    end

    let(:id_map) do
      {
        'Group' => {
          1001 => groups[0].id,
          1002 => groups[1].id,
          1003 => groups[2].id,
        }
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     id_map,
      }
    end

    let(:imported_user) do
      {
        firstname:  'John',
        lastname:   'Doe',
        login:      'freshdesk@example.com',
        email:      'freshdesk@example.com',
        active:     true,
        last_login: DateTime.parse('2021-05-10T07:52:58Z'),
      }
    end

    before do
      stub_request(:get, 'https://yours.freshdesk.com/api/v2/agents/me').to_return(status: 200, body: '', headers: {})
    end

    it 'imports user correctly (increased user count)' do
      expect { process(process_payload) }.to change(User, :count).by(1)
    end

    it 'imports user data correctly' do
      process(process_payload)
      expect(User.last).to have_attributes(imported_user)
    end

    it 'sets user roles correctly for admin user' do
      allow(Sequencer::Unit::Import::Freshdesk::Agent::Mapping).to receive(:admin_id).and_return(1001)
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

    context 'with deleted flag in resource' do
      before do
        resource['contact']['deleted'] = true
        imported_user[:active] = false
      end

      it 'imports user data correctly' do
        process(process_payload)
        expect(User.last).to have_attributes(imported_user)
      end
    end
  end
end
