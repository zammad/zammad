# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationModel::CanLookupSearchIndexAttributes::RequestCache do
  def object_manager_attribute_queries(matching = 'object_manager_attributes')
    count      = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      count += 1 if payload[:sql].include?(matching) && !payload[:cached]
    end

    yield

    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  before do
    create(:object_manager_attribute_integer, name: 'inttest')
  end

  describe '.integer_fields' do
    it 'returns the integer attributes of the given class' do
      expect(described_class.integer_fields('Ticket')).to include('inttest')
    end

    it 'asks the database once per class', :aggregate_failures do
      expect(object_manager_attribute_queries { 3.times { described_class.integer_fields('Ticket') } }).to eq(1)
      expect(object_manager_attribute_queries { described_class.integer_fields('User') }).to eq(1)
    end
  end

  describe '.refresh' do
    before do
      described_class.refresh
      described_class.integer_fields('Ticket')
    end

    it 'keeps the attributes when no object manager attribute was changed' do
      queries = object_manager_attribute_queries do
        described_class.refresh
        described_class.integer_fields('Ticket')
      end

      expect(queries).to eq(1)
    end

    it 'drops the attributes when an object manager attribute was changed' do
      create(:object_manager_attribute_integer, name: 'inttest2')

      described_class.refresh

      expect(described_class.integer_fields('Ticket')).to include('inttest', 'inttest2')
    end
  end

  describe 'building a search index document' do
    let(:ticket) { create(:ticket) }

    before do
      create_list(:ticket_article, 3, ticket:)

      allow(SearchIndexBackend).to receive(:add)
    end

    it 'asks once whether an object manager attribute was changed' do
      expect(object_manager_attribute_queries('MAX("object_manager_attributes"."updated_at")') { ticket.search_index_update_backend }).to eq(1)
    end

    it 'sees an integer attribute added since the last document' do
      ticket.search_index_attribute_lookup_with_refresh
      create(:object_manager_attribute_integer, name: 'inttest2')
      ticket.search_index_attribute_lookup_with_refresh

      expect(described_class.integer_fields('Ticket')).to include('inttest2')
    end
  end
end
