# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::Customer do

  def creates_with(zammad_structure)
    allow(import_object).to receive(:create).with(zammad_structure).and_return(existing_object)

    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(existing_object)

    expect(existing_object).to receive(:update!).with(zammad_structure)
    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def load_customer_json(file)
    json_fixture("import/otrs/customer/#{file}")
  end

  let(:import_object) { Organization }
  let(:existing_object) { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }

  context 'Organization' do

    let(:object_structure) { load_customer_json('default') }
    let(:zammad_structure) do
      {
        created_by_id: '1',
        updated_by_id: '1',
        active:        false,
        updated_at:    '2014-06-06 12:41:03',
        created_at:    '2014-06-06 12:41:03',
        name:          'test922896',
        note:          'test922896'
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'OTRS CustomerID' do

    let(:customer_id) { 'test922896' }
    let(:object_structure) { load_customer_json('default') }
    let(:otrs_dummy_response) do
      [
        object_structure
      ]
    end

    it 'responds to by_customer_id' do
      expect(described_class).to respond_to('by_customer_id')
    end

    it 'finds Organizations by OTRS CustomerID' do
      allow(Import::OTRS::Requester).to receive(:load).and_return(otrs_dummy_response)
      allow(import_object).to receive(:find_by).with(name: customer_id).and_return(existing_object)

      expect(described_class.by_customer_id(customer_id)).to be(existing_object)
    end
  end
end
