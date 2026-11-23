# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexBackend::Bulk, searchindex: true do
  subject(:bulk) { described_class.new('Ticket') }

  let(:tickets)   { create_list(:ticket, 3) }
  let(:documents) { tickets.map(&:search_index_attribute_lookup) }

  def indexed_ids
    SearchIndexBackend.refresh
    SearchIndexBackend.search('*', 'Ticket', sort_by: ['id'], order_by: ['asc']).map { |item| item[:id].to_i }
  end

  describe '#flush' do
    it 'indexes all added documents with one request', :aggregate_failures do
      allow(SearchIndexBackend).to receive(:make_request).and_call_original

      documents.each { |document| bulk.add(document) }
      bulk.flush

      expect(SearchIndexBackend).to have_received(:make_request).with(%r{/_bulk}, any_args).once
      expect(bulk.failed_ids).to be_empty
      expect(indexed_ids).to eq(tickets.map(&:id))
    end

    it 'does not follow a redirect with the documents' do
      allow(UserAgent).to receive(:post).and_call_original

      documents.each { |document| bulk.add(document) }
      bulk.flush

      expect(UserAgent).to have_received(:post).with(%r{/_bulk}, {}, include(:send_as_raw_body, do_not_follow_redirects: true))
    end

    it 'sends nothing without documents' do
      allow(SearchIndexBackend).to receive(:make_request)

      bulk.flush

      expect(SearchIndexBackend).not_to have_received(:make_request)
    end

    context 'with an attachment' do
      let(:tickets) { [create(:ticket)] }

      before do
        article = create(:ticket_article, ticket: tickets.first)

        create(:store,
               object:   'Ticket::Article',
               o_id:     article.id,
               data:     Rails.root.join('test/data/elasticsearch/es-normal.txt').binread,
               filename: 'es-normal.txt')
      end

      it 'runs the attachment pipeline' do
        documents.each { |document| bulk.add(document) }
        bulk.flush
        SearchIndexBackend.refresh

        expect(SearchIndexBackend.search('text66', 'Ticket')).to eq([{ id: tickets.first.id.to_s, type: 'Ticket' }])
      end
    end

    context 'when Elasticsearch refuses a document' do
      before do
        documents.second['created_at'] = 'not a date'
      end

      it 'reports the id of this document and indexes the others', :aggregate_failures do
        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(bulk.failed_ids).to eq([tickets.second.id])
        expect(indexed_ids).to eq([tickets.first.id, tickets.third.id])
      end
    end

    context 'when the answer does not confirm the documents' do
      before do
        allow(SearchIndexBackend).to receive(:make_request).and_return(UserAgent::Result.new(success: true, code: '200', data: {}))
      end

      it 'reports the ids of all documents of the request' do
        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(bulk.failed_ids).to eq(tickets.map(&:id))
      end
    end

    context 'when the answer has no valid status for a document' do
      before do
        items = [{ 'index' => { 'status' => 201 } }, { 'index' => { 'status' => true } }, { 'index' => { 'status' => '200' } }]

        allow(SearchIndexBackend).to receive(:make_request).and_return(UserAgent::Result.new(success: true, code: '200', data: { 'items' => items }))
      end

      it 'reports the ids of these documents' do
        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(bulk.failed_ids).to eq([tickets.second.id, tickets.third.id])
      end
    end

    context 'when Elasticsearch is busy' do
      let(:busy) { UserAgent::Result.new(success: false, code: '429') }

      before do
        allow(bulk).to receive(:sleep)
      end

      it 'waits and sends the request again', :aggregate_failures do
        calls = 0

        allow(SearchIndexBackend).to receive(:make_request).and_wrap_original do |original, *args, **options|
          next original.call(*args, **options) if args.first.exclude?('/_bulk') || (calls += 1) > 2

          busy
        end

        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(bulk).to have_received(:sleep).with(described_class::BUSY_DELAY).twice
        expect(bulk.failed_ids).to be_empty
        expect(indexed_ids).to eq(tickets.map(&:id))
      end

      it 'reports the ids of all documents when it stays busy', :aggregate_failures do
        allow(SearchIndexBackend).to receive(:make_request).and_return(busy)

        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(SearchIndexBackend).to have_received(:make_request).exactly(described_class::BUSY_TRIES).times
        expect(bulk.failed_ids).to eq(tickets.map(&:id))
      end

      context 'with a single document' do
        before do
          items = [{ 'index' => { 'status' => 201 } }, { 'index' => { 'status' => 429 } }, { 'index' => { 'status' => 201 } }]
          calls = 0

          allow(SearchIndexBackend).to receive(:make_request).and_wrap_original do |original, *args, **options|
            next original.call(*args, **options) if args.first.exclude?('/_bulk')
            next UserAgent::Result.new(success: true, code: '200', data: { 'items' => items }) if (calls += 1) == 1

            UserAgent::Result.new(success: true, code: '200', data: { 'items' => [{ 'index' => { 'status' => 201 } }] })
          end
        end

        it 'sends only this document again', :aggregate_failures do
          documents.each { |document| bulk.add(document) }
          bulk.flush

          expect(SearchIndexBackend).to have_received(:make_request).with(%r{/_bulk}, include(data: satisfy { |body| body.lines.size == 2 })).once
          expect(bulk.failed_ids).to be_empty
        end
      end
    end

    context 'when the request raises an error' do
      before do
        allow(bulk).to receive(:sleep)
        allow(SearchIndexBackend).to receive(:make_request).and_raise('no connection')
      end

      it 'sends it again and reports the ids of all documents when it keeps failing', :aggregate_failures do
        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(SearchIndexBackend).to have_received(:make_request).exactly(described_class::BUSY_TRIES).times
        expect(bulk.failed_ids).to eq(tickets.map(&:id))
      end
    end

    context 'when Elasticsearch refuses the request' do
      before do
        allow(SearchIndexBackend).to receive(:make_request).and_return(UserAgent::Result.new(success: false, code: '400'))
      end

      it 'reports the ids of all documents of the request without sending it again', :aggregate_failures do
        documents.each { |document| bulk.add(document) }
        bulk.flush

        expect(SearchIndexBackend).to have_received(:make_request).once
        expect(bulk.failed_ids).to eq(tickets.map(&:id))
      end
    end
  end

  describe '#add' do
    before do
      stub_const("#{described_class}::MAX_REQUEST_SIZE", documents.map { |document| document.to_json.bytesize }.max + 100)
      allow(SearchIndexBackend).to receive(:make_request).and_call_original
    end

    it 'sends a request of its own when the size limit is reached', :aggregate_failures do
      documents.each { |document| bulk.add(document) }
      bulk.flush

      expect(SearchIndexBackend).to have_received(:make_request).with(%r{/_bulk}, any_args).exactly(3).times
      expect(indexed_ids).to eq(tickets.map(&:id))
    end
  end
end
