# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::Ticket do

  def creates_with(zammad_structure)
    allow(import_object).to receive(:new).with(zammad_structure).and_call_original

    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(existing_object)
    allow(existing_object).to receive(:update!).with(zammad_structure)

    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def load_ticket_json(file)
    json_fixture("import/otrs/ticket/#{file}")
  end

  def import_backend_expectations
    expect(Import::OTRS::ArticleCustomerFactory).to receive(:import)
    expect(Import::OTRS::ArticleFactory).to receive(:import)
    expect(Import::OTRS::HistoryFactory).to receive(:import)
    allow(::User).to receive(:find_by).and_return(nil)
    # needed, otherwise 'ActiveRecord::UnknownAttributeError' for
    # DynamicFields will arise
    allow(Import::OTRS::DynamicFieldFactory).to receive('skip_field?').and_return(true)
  end

  let(:import_object) { Ticket }
  let(:existing_object) { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }

  context 'default' do

    let(:object_structure) { load_ticket_json('default') }
    let(:zammad_structure) do
      {
        title:         'test #3',
        owner_id:      1,
        customer_id:   1,
        created_by_id: '3',
        updated_by_id: 1,
        updated_at:    '2014-11-21 00:21:08',
        created_at:    '2014-11-21 00:17:40',
        number:        '20141121305000012',
        group_id:      '1',
        state_id:      '2',
        priority_id:   '3',
        id:            '730',
        close_at:      '2014-11-21 00:21:08'
      }
    end

    it 'creates' do
      import_backend_expectations
      creates_with(zammad_structure)
    end

    it 'updates' do
      import_backend_expectations
      updates_with(zammad_structure)
    end
  end

  context 'no title' do

    let(:object_structure) { load_ticket_json('no_title') }
    let(:zammad_structure) do
      {
        title:         '**EMPTY**',
        owner_id:      1,
        customer_id:   1,
        created_by_id: '3',
        updated_by_id: 1,
        updated_at:    '2014-11-21 00:21:08',
        created_at:    '2014-11-21 00:17:40',
        number:        '20141121305000012',
        group_id:      '1',
        state_id:      '2',
        priority_id:   '3',
        id:            '730',
        close_at:      '2014-11-21 00:21:08'
      }
    end

    it 'creates' do
      import_backend_expectations
      creates_with(zammad_structure)
    end

    it 'updates' do
      import_backend_expectations
      updates_with(zammad_structure)
    end
  end

  context 'unknown customer' do

    let(:object_structure) { load_ticket_json('unknown_customer') }
    let(:zammad_structure) do
      {
        owner_id:      1,
        customer_id:   1337,
        created_by_id: 1337,
        updated_by_id: 1,
        updated_at:    '2014-07-17 14:29:44',
        created_at:    '2014-07-17 14:29:43',
        number:        '2014071754002471',
        group_id:      '2',
        state_id:      '1',
        priority_id:   '3',
        title:         'Ask me about performance',
        id:            '540'
      }
    end

    def article_based_customer_expectation
      user = instance_double(::User)
      allow(user).to receive(:id).and_return(1337)
      allow(Import::OTRS::ArticleCustomer).to receive(:find).with(hash_including('From' => '458@company-sales.com')).and_return(user)
    end

    it 'creates' do
      import_backend_expectations
      article_based_customer_expectation
      creates_with(zammad_structure)
    end

    it 'updates' do
      import_backend_expectations
      article_based_customer_expectation
      updates_with(zammad_structure)
    end
  end
end
