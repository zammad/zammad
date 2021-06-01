# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::Priority do

  def creates_with(zammad_structure)
    allow(import_object).to receive(:new).with(zammad_structure).and_call_original

    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(existing_object)

    expect(existing_object).to receive(:update!).with(zammad_structure)
    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def load_priority_json(file)
    json_fixture("import/otrs/priority/#{file}")
  end

  let(:import_object) { Ticket::Priority }
  let(:existing_object) { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }

  context 'default' do

    let(:object_structure) { load_priority_json('default') }
    let(:zammad_structure) do
      {
        created_by_id: '1',
        updated_by_id: '1',
        active:        true,
        updated_at:    '2014-04-28 10:53:18',
        created_at:    '2014-04-28 10:53:18',
        ui_color:      'high-priority',
        ui_icon:       'important',
        name:          '4 high',
        id:            '4'
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'normal' do

    let(:object_structure) { load_priority_json('normal') }
    let(:zammad_structure) do
      {
        created_by_id: '1',
        updated_by_id: '1',
        active:        true,
        updated_at:    '2014-04-28 10:53:18',
        created_at:    '2014-04-28 10:53:18',
        ui_color:      nil,
        ui_icon:       nil,
        name:          '3 normal',
        id:            '3'
      }
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'low' do

    let(:object_structure) { load_priority_json('low') }
    let(:zammad_structure) do
      {
        created_by_id: '1',
        updated_by_id: '1',
        active:        true,
        updated_at:    '2014-04-28 10:53:18',
        created_at:    '2014-04-28 10:53:18',
        ui_color:      'low-priority',
        ui_icon:       'low-priority',
        name:          '2 low',
        id:            '2'
      }
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end
end
