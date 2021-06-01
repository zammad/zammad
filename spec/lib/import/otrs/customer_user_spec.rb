# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::CustomerUser do

  def creates_with(zammad_structure)
    allow_organization_lookup
    allow(import_object).to receive(:new).with(zammad_structure).and_call_original

    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow_organization_lookup
    allow(import_object).to receive(:find_by).and_return(existing_object)
    # we delete the :role_ids from the zammad_structure to make sure that
    # a) role_ids call returns the initial role_ids
    # b) and update! gets called without them
    allow(existing_object).to receive(:role_ids).and_return(zammad_structure.delete(:role_ids)).at_least(:once)

    expect(existing_object).to receive(:update!).with(zammad_structure)
    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def allow_organization_lookup
    allow(Import::OTRS::Customer).to receive(:by_customer_id).and_return(organization)
    allow(organization).to receive(:id).and_return(organization_id)
  end

  def load_customer_json(file)
    json_fixture("import/otrs/customer_user/#{file}")
  end

  let(:import_object) { User }
  let(:existing_object) { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }
  let(:organization) { instance_double(Organization) }
  let(:organization_id) { 1337 }

  context 'regular user' do

    let(:object_structure) { load_customer_json('default') }
    let(:zammad_structure) do
      {
        created_by_id:   '1',
        updated_by_id:   '1',
        active:          true,
        source:          'OTRS Import',
        organization_id: 1337,
        role_ids:        [3],
        updated_at:      '2014-06-07 02:31:31',
        created_at:      '2014-06-07 02:31:31',
        note:            '',
        email:           'qa100@t-online.de',
        firstname:       'test669673',
        lastname:        'test669673',
        login:           'test669673',
        password:        'f8be19af2f25837a31eff9131b0e47a5173290652c04a48b49b86474d48825ee',
        phone:           nil,
        fax:             nil,
        mobile:          nil,
        street:          nil,
        zip:             nil,
        city:            nil,
        country:         nil
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'no timestamps' do

    let(:object_structure) { load_customer_json('no_timestamps') }
    let(:zammad_structure) do
      {
        created_by_id:   '1',
        updated_by_id:   '1',
        active:          true,
        source:          'OTRS Import',
        organization_id: 1337,
        role_ids:        [3],
        updated_at:      DateTime.current,
        created_at:      DateTime.current,
        note:            '',
        email:           'qa100@t-online.de',
        firstname:       'test669673',
        lastname:        'test669673',
        login:           'test669673',
        password:        'f8be19af2f25837a31eff9131b0e47a5173290652c04a48b49b86474d48825ee',
        phone:           nil,
        fax:             nil,
        mobile:          nil,
        street:          nil,
        zip:             nil,
        city:            nil,
        country:         nil
      }
    end

    before do
      travel_to DateTime.current
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'regular user with capitalized email' do

    let(:object_structure) { load_customer_json('capital_email') }
    let(:zammad_structure) do
      {
        created_by_id:   '1',
        updated_by_id:   '1',
        active:          true,
        source:          'OTRS Import',
        organization_id: 1337,
        role_ids:        [3],
        updated_at:      '2014-06-07 02:31:31',
        created_at:      '2014-06-07 02:31:31',
        note:            '',
        email:           'qa100@t-online.de',
        firstname:       'test669673',
        lastname:        'test669673',
        login:           'test669673',
        password:        'f8be19af2f25837a31eff9131b0e47a5173290652c04a48b49b86474d48825ee',
        phone:           nil,
        fax:             nil,
        mobile:          nil,
        street:          nil,
        zip:             nil,
        city:            nil,
        country:         nil
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'regular user with camelcase login' do

    let(:object_structure) { load_customer_json('camel_case_login') }
    let(:zammad_structure) do
      {
        created_by_id:   '1',
        updated_by_id:   '1',
        active:          true,
        source:          'OTRS Import',
        organization_id: 1337,
        role_ids:        [3],
        updated_at:      '2014-06-07 02:31:31',
        created_at:      '2014-06-07 02:31:31',
        note:            '',
        email:           'qa100@t-online.de',
        firstname:       'test669673',
        lastname:        'test669673',
        login:           'test669673',
        password:        'f8be19af2f25837a31eff9131b0e47a5173290652c04a48b49b86474d48825ee',
        phone:           nil,
        fax:             nil,
        mobile:          nil,
        street:          nil,
        zip:             nil,
        city:            nil,
        country:         nil
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end
end
