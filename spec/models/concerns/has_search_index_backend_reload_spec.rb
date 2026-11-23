# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HasSearchIndexBackend, searchindex: true, type: :model do
  describe '.search_index_reload' do
    let(:tickets) { create_list(:ticket, 3) }

    def indexed_ids(index)
      SearchIndexBackend.refresh
      SearchIndexBackend.search('*', index, sort_by: ['id'], order_by: ['asc'], limit: 100).map { |item| item[:id].to_i }
    end

    before do
      tickets

      allow(SearchIndexBackend).to receive(:add).and_call_original
      allow(SearchIndexBackend).to receive(:make_request).and_call_original
    end

    it 'indexes all records with a bulk request', :aggregate_failures do
      Ticket.search_index_reload(silent: true)

      expect(SearchIndexBackend).to have_received(:make_request).with(%r{/_bulk}, any_args).once
      expect(SearchIndexBackend).not_to have_received(:add)
      expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
    end

    it 'prints the progress once per batch with records', :aggregate_failures do
      stub_const('SearchIndexBackend::Reload::Records::BATCH_SIZE', 2)

      expect(Ticket.count).to eq(4)
      expect { Ticket.search_index_reload }.to output("\r    2/4\r    4/4").to_stdout
      expect { Chat::Session.search_index_reload }.not_to output.to_stdout
    end

    it 'does not index records which are excluded from the search index' do
      User.search_index_reload(silent: true)

      expect(indexed_ids('User')).to eq(User.where.not(id: 1).reorder(:id).ids)
    end

    context 'with more records than one bulk request takes' do
      before do
        stub_const('SearchIndexBackend::Reload::Records::BULK_SIZE', 2)
      end

      it 'sends several bulk requests', :aggregate_failures do
        Ticket.search_index_reload(silent: true)

        expect(SearchIndexBackend).to have_received(:make_request).with(%r{/_bulk}, any_args).exactly((Ticket.count / 2.0).ceil).times
        expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      end
    end

    context 'when an integer attribute is added after a reload', db_strategy: :reset do
      before do
        Ticket.search_index_reload(silent: true)

        create(:object_manager_attribute_integer, name: 'inttest', data_option: { 'default' => 0, 'min' => 0, 'max' => 99_999_999 })
        ObjectManager::Attribute.migration_execute

        Ticket.find(tickets.first.id).update!(inttest: 1_021_052_349)
      end

      it 'indexes its values as text with the next reload' do
        Ticket.search_index_reload(silent: true)
        SearchIndexBackend.refresh

        expect(SearchIndexBackend.search('102105', 'Ticket')).to eq([{ id: tickets.first.id.to_s, type: 'Ticket' }])
      end
    end

    context 'when a record is destroyed after its document was built' do
      before do
        allow_any_instance_of(Ticket).to receive(:search_index_attribute_lookup).and_wrap_original do |original, **options|
          attributes = original.call(**options)

          original.receiver.destroy! if original.receiver.id == tickets.first.id

          attributes
        end
      end

      it 'leaves no document of this record', :aggregate_failures do
        Ticket.search_index_reload(silent: true)

        expect(Ticket).not_to exist(tickets.first.id)
        expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      end
    end

    context 'when a record is destroyed after the bulk request refused it' do
      before do
        allow_any_instance_of(Ticket).to receive(:search_index_attribute_lookup).and_wrap_original do |original, **options|
          attributes = original.call(**options)

          attributes['created_at'] = 'not a date' if original.receiver.id == tickets.first.id && original.receiver.persisted?

          attributes
        end

        allow(SearchIndexBackend).to receive(:add).and_wrap_original do |original, type, data|
          if data['id'] == tickets.first.id
            Ticket.find(data['id']).destroy!
            data['created_at'] = Time.current.iso8601
          end

          original.call(type, data)
        end
      end

      it 'leaves no document of this record and keeps the others', :aggregate_failures do
        other_ids = Ticket.where.not(id: tickets.first.id).reorder(:id).ids

        Ticket.search_index_reload(silent: true)

        expect(Ticket).not_to exist(tickets.first.id)
        expect(Ticket.reorder(:id).ids).to eq(other_ids)
        expect(indexed_ids('Ticket')).to eq(other_ids)
      end
    end

    context 'when Elasticsearch refuses a record in the bulk request' do
      before do
        refused = false

        allow_any_instance_of(Ticket).to receive(:search_index_attribute_lookup).and_wrap_original do |original, **options|
          attributes = original.call(**options)

          if original.receiver.id == tickets.first.id && !refused
            refused = true
            attributes['created_at'] = 'not a date'
          end

          attributes
        end
      end

      it 'indexes this record with a single request', :aggregate_failures do
        Ticket.search_index_reload(silent: true)

        expect(SearchIndexBackend).to have_received(:add).with('Ticket', include('id' => tickets.first.id)).once
        expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      end
    end

    context 'when the document of a record cannot be built' do
      before do
        allow_any_instance_of(Ticket).to receive(:search_index_attribute_lookup).and_wrap_original do |original, **options|
          raise 'broken record' if original.receiver.id == tickets.first.id

          original.call(**options)
        end
        stub_const('SearchIndexBackend::Reload::Records::RETRY_DELAY', 0)
        allow(Rails.logger).to receive(:error).and_call_original
      end

      it 'continues with the other records', :aggregate_failures do
        Ticket.search_index_reload(silent: true)

        expect(Rails.logger).to have_received(:error).with(%r{Unable to send Ticket\.find}).once
        expect(indexed_ids('Ticket')).to eq(Ticket.where.not(id: tickets.first.id).reorder(:id).ids)
      end
    end

    context 'when the bulk request fails' do
      before do
        allow(SearchIndexBackend).to receive(:make_request).with(%r{/_bulk}, any_args).and_return(UserAgent::Result.new(success: false, code: '400'))
        stub_const('SearchIndexBackend::Reload::Records::RETRY_DELAY', 0)
        allow(Rails.logger).to receive(:error).and_call_original
      end

      it 'indexes the records with single requests', :aggregate_failures do
        Ticket.search_index_reload(silent: true)

        expect(SearchIndexBackend).to have_received(:add).exactly(Ticket.count).times
        expect(indexed_ids('Ticket')).to eq(Ticket.reorder(:id).ids)
      end

      context 'when a record fails with a single request, too' do
        before do
          allow(SearchIndexBackend).to receive(:add).and_wrap_original do |original, type, data|
            raise 'broken record' if data['id'] == tickets.first.id

            original.call(type, data)
          end
        end

        it 'continues with the other records', :aggregate_failures do
          Ticket.search_index_reload(silent: true)

          expect(Rails.logger).to have_received(:error).with(%r{Unable to send Ticket\.find}).once
          expect(indexed_ids('Ticket')).to eq(Ticket.where.not(id: tickets.first.id).reorder(:id).ids)
        end
      end

      context 'when a record is destroyed before the reload stops at the limit of failures' do
        before do
          stub_const('SearchIndexBackend::Reload::Records::TOLERANCE', 2)

          allow(SearchIndexBackend).to receive(:add).and_wrap_original do |original, type, data|
            raise 'broken record' if data['id'] != tickets.last.id

            Ticket.find(data['id']).destroy!
            original.call(type, data)
          end
        end

        it 'leaves no document of this record', :aggregate_failures do
          expect { Ticket.search_index_reload(silent: true) }.to raise_error(%r{Unable to send Ticket\.find})

          expect(Ticket).not_to exist(tickets.last.id)
          expect(indexed_ids('Ticket')).to be_empty
        end
      end

      context 'when ten records fail with a single request, too' do
        let(:tickets) { create_list(:ticket, 10) }

        before do
          stub_const('SearchIndexBackend::Reload::Records::BULK_SIZE', 2)
          allow(SearchIndexBackend).to receive(:add).and_raise('broken record')
        end

        it 'stops the reload at the tenth record', :aggregate_failures do
          expect { Ticket.search_index_reload(silent: true) }.to raise_error(%r{Unable to send Ticket\.find\(\d+\)\.search_index_update_backend backend})
          expect(Rails.logger).to have_received(:error).with(%r{Unable to send Ticket\.find}).exactly(10).times
        end
      end
    end
  end
end
