# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::User do

  def creates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(nil)
    allow(import_object).to receive(:new).with(zammad_structure).and_call_original

    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(existing_object)
    # we delete the :role_ids from the zammad_structure to make sure that
    # a) role_ids call returns the initial role_ids
    # b) and update! gets called without them
    allow(existing_object).to receive(:role_ids).and_return(zammad_structure.delete(:role_ids))

    expect(existing_object).to receive(:update!).with(zammad_structure)
    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def role_delete_expecations(role_ids); end

  def load_user_json(file)
    json_fixture("import/otrs/user/#{file}")
  end

  def prepare_expectations
    requester_expectations
    user_expectations
  end

  def user_expectations
    allow(User).to receive(:where).and_return([])
  end

  # this is really bad and should get improved!
  # these are integration tests that will likely fail
  # soon - sorry :)
  def requester_expectations
    queue_list = [
      {
        'QueueID' => '1',
        'GroupID' => '2',
      }
    ]
    allow(Import::OTRS::Requester).to receive(:load).with('Queue').and_return(queue_list)

    group_list = [
      {
        'ID'   => '2',
        'Name' => 'user',
      },
      {
        'ID'   => '3',
        'Name' => 'admin',
      },
    ]
    allow(Import::OTRS::Requester).to receive(:load).with('Group').and_return(group_list)

    role_list = [{ 'ID' => '3', 'GroupIDs' => { '2' => ['rw'], '3' => ['rw'] } }]
    allow(Import::OTRS::Requester).to receive(:load).with('Role').and_return(role_list)
  end

  let(:import_object) { ::User }
  let(:existing_object) { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }

  context 'default' do

    let(:object_structure) { load_user_json('default') }
    let(:zammad_structure) do
      {
        created_by_id: 1,
        updated_by_id: 1,
        active:        true,
        source:        'OTRS Import',
        role_ids:      [2, 1],
        group_ids:     ['1'],
        password:      '{sha2}9faaba2ab242a99bbb6992e9424386375f6757c17e6484ae570f39d9cad9f28ea',
        updated_at:    '2014-04-28 10:53:18',
        created_at:    '2014-04-28 10:53:18',
        id:            '1',
        email:         'root@localhost',
        firstname:     'Admin',
        lastname:      'OTRS',
        login:         'root@localhost'
      }
    end

    it 'creates' do
      prepare_expectations
      creates_with(zammad_structure)
    end

    it 'updates' do
      prepare_expectations
      updates_with(zammad_structure)
    end
  end

  context 'no groups' do

    let(:object_structure) { load_user_json('no_groups') }
    let(:zammad_structure) do
      {
        created_by_id: 1,
        updated_by_id: 1,
        active:        true,
        source:        'OTRS Import',
        role_ids:      [2, 1],
        group_ids:     [],
        password:      '{sha2}9edb001ad7900daea0622d89225c9ca729749fd12ae5ea044f072d1b7c56c8cc',
        updated_at:    '2014-11-14 00:53:20',
        created_at:    '2014-11-14 00:53:20',
        id:            '6',
        email:         'agent-2-for-role-2@example.com',
        firstname:     'agent-2-for-role-2',
        lastname:      'agent-2-for-role-2',
        login:         'agent-2-for-role-2'
      }
    end

    it 'creates' do
      prepare_expectations
      creates_with(zammad_structure)
    end

    it 'updates' do
      prepare_expectations
      updates_with(zammad_structure)
    end
  end

  context 'capital email' do

    let(:object_structure) { load_user_json('capital_email') }
    let(:zammad_structure) do
      {
        created_by_id: 1,
        updated_by_id: 1,
        active:        true,
        source:        'OTRS Import',
        role_ids:      [2, 1],
        group_ids:     ['1'],
        password:      '{sha2}9faaba2ab242a99bbb6992e9424386375f6757c17e6484ae570f39d9cad9f28ea',
        updated_at:    '2014-04-28 10:53:18',
        created_at:    '2014-04-28 10:53:18',
        id:            '1',
        email:         'root@localhost',
        firstname:     'Admin',
        lastname:      'OTRS',
        login:         'root@localhost'
      }
    end

    it 'creates' do
      prepare_expectations
      creates_with(zammad_structure)
    end

    it 'updates' do
      prepare_expectations
      updates_with(zammad_structure)
    end
  end

  context 'regular user with camel case login' do

    let(:object_structure) { load_user_json('camel_case_login') }
    let(:zammad_structure) do
      {
        created_by_id: 1,
        updated_by_id: 1,
        active:        true,
        source:        'OTRS Import',
        role_ids:      [2, 1],
        group_ids:     ['1'],
        password:      '{sha2}9faaba2ab242a99bbb6992e9424386375f6757c17e6484ae570f39d9cad9f28ea',
        updated_at:    '2014-04-28 10:53:18',
        created_at:    '2014-04-28 10:53:18',
        id:            '1',
        email:         'root@localhost',
        firstname:     'Admin',
        lastname:      'OTRS',
        login:         'root@localhost'
      }
    end

    it 'creates' do
      prepare_expectations
      creates_with(zammad_structure)
    end

    it 'updates' do
      prepare_expectations
      updates_with(zammad_structure)
    end
  end

end
