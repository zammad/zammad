# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::VectorDB, :aggregate_failures do
  subject(:instance) { described_class.new }

  describe '.ping!' do
    context 'when version is not suitable' do
      before do
        allow(instance).to receive(:verify_es_version!)
          .and_raise(AI::VectorDB::Error, 'Incompatible Elasticsearch version')
      end

      it 'raises AI::VectorDB::Error' do
        expect { instance.ping! }.to raise_error(AI::VectorDB::Error, 'Incompatible Elasticsearch version')
      end
    end

    context 'when ai_embeddings index does not exist' do
      before do
        allow(instance).to receive(:verify_es_version!)
        allow(instance).to receive(:index_exists)
          .and_raise(AI::VectorDB::MigrationError, 'Elasticsearch index does not exist')
      end

      it 'raises AI::VectorDB::MigrationError' do
        expect { instance.ping! }.to raise_error(AI::VectorDB::MigrationError, 'Elasticsearch index does not exist')
      end
    end

    context 'when version is suitable and ai_embeddings index exists' do
      before do
        allow(instance).to receive_messages(verify_es_version!: nil, index_exists: nil)
      end

      it 'raises no error' do
        expect(instance.ping!).to be_nil
      end
    end
  end

  describe '.migrate' do
    context 'when migration fails' do
      before do
        allow(instance).to receive(:client)
          .and_raise(Elastic::Transport::Transport::Error, 'Migration error')
      end

      it 'raises AI::VectorDB::Error' do
        expect { instance.migrate }.to raise_error(AI::VectorDB::Error, 'The Elasticsearch index could not be created')
      end
    end

    context 'when migration succeeds' do
      before do
        indices = instance_double(Elasticsearch::API::Indices::Actions)
        allow(indices).to receive_messages(create: Elasticsearch::API::Response, exists?: false)
        allow_any_instance_of(Elasticsearch::Client).to receive_messages(indices: indices, ping: true)
      end

      it 'creates the index successfully' do
        expect(instance.migrate).to be(Elasticsearch::API::Response)
      end
    end
  end

  describe '.drop' do
    context 'when index does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(false)
      end

      it 'does not raise an error' do
        expect { instance.drop }.not_to raise_error
      end
    end

    context 'when index exists' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client.indices).to receive(:delete).with(index: instance.index_name)
          .and_return(true)
      end

      it 'deletes the index successfully' do
        expect(instance.drop).to be(true)
      end
    end
  end

  describe '.create' do
    let(:content)     { 'test content' }
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }
    let(:embedding)   { [0.1, 0.2, 0.3] }
    let(:metadata)    { { key: 'value' } }

    context 'when index does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(false)
      end

      it 'raises AI::VectorDB::MigrationError' do
        expect { instance.create(content:, object_id:, object_name:, embedding:, metadata:) }
          .to raise_error(AI::VectorDB::MigrationError, 'Elasticsearch index does not exist')
      end
    end

    context 'when object already exists' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive(:exists?).and_return(true)
      end

      it 'does not create the document successfully' do
        expect(instance.create(content:, object_id:, object_name:, embedding:, metadata:)).to be_nil
      end
    end

    context 'when object does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive_messages(exists?: false, index: true)
      end

      it 'creates the document successfully' do
        expect(instance.create(content:, object_id:, object_name:, embedding:, metadata:)).to be_truthy
      end
    end
  end

  describe '.find' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }

    context 'when content is given' do
      let(:content) { 'test content' }

      context 'when no document is found' do
        before do
          allow(instance).to receive(:client)
            .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
          allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
            .and_return(true)
          allow(instance.client).to receive_messages(exists?: false, get: nil)
        end

        it 'returns nil' do
          expect(instance.find(object_id:, object_name:, content:)).to be_nil
        end
      end

      context 'when document is found' do
        let(:document) do
          {
            _id:     "#{object_name}-#{object_id}",
            _index:  instance.index_name,
            _source: {
              object_id:,
              object_name:,
              content:     'test content',
              embedding:   [0.1, 0.2, 0.3],
              metadata:    {}
            }
          }
        end

        before do
          allow(instance).to receive(:client)
            .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
          allow(instance.client).to receive_messages(exists?: true, get: document)
        end

        it 'returns the document' do
          expect(instance.find(object_id:, object_name:, content:)).to eq(document)
          expect(instance.client).to have_received(:get).with(
            index: instance.index_name,
            id:    "#{object_name}-#{object_id}-#{Digest::SHA256.hexdigest(content)}"
          )
        end
      end
    end

    context 'when content is not given' do
      let(:search_response) { { 'hits' => { 'hits' => [{ '_id' => 'ticket-1-abc' }] } } }

      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client))
        allow(instance.client).to receive(:search).and_return(double(body: search_response))
      end

      it 'searches by object_id and object_name and returns all results' do
        result = instance.find(object_id:, object_name:)

        expect(instance.client).to have_received(:search).with(
          index: instance.index_name,
          body:  {
            size:  10_000,
            query: {
              bool: {
                filter: [
                  { term: { object_id:   object_id } },
                  { term: { object_name: object_name } }
                ]
              }
            }
          }
        )
        expect(result).to eq(search_response.dig('hits', 'hits'))
      end
    end
  end

  describe '#knn' do
    let(:embedding)       { [0.1, 0.2, 0.3] }
    let(:search_response) { { 'hits' => { 'hits' => [] } } }

    before do
      allow(instance).to receive(:index_exists)
      allow(instance).to receive(:client).and_return(instance_double(Elasticsearch::Client))
      allow(instance.client).to receive(:search).and_return(double(body: search_response))
    end

    it 'searches without a filter when none is given' do
      instance.knn(embedding:, k: 3)

      expect(instance.client).to have_received(:search).with(
        index: instance.index_name,
        body:  { query: { knn: hash_excluding(:filter) } }
      )
    end

    it 'builds a single term clause for a scalar filter value' do
      instance.knn(embedding:, k: 3, filter: { object_name: 'Ticket' })

      expect(instance.client).to have_received(:search).with(
        index: instance.index_name,
        body:  { query: { knn: hash_including(filter: { term: { object_name: 'Ticket' } }) } }
      )
    end

    it 'combines scalar and array filter values into a bool filter (term + terms)' do
      instance.knn(embedding:, k: 3, filter: { object_name: 'KnowledgeBase::Answer::Translation', object_id: [1, 2] })

      expect(instance.client).to have_received(:search).with(
        index: instance.index_name,
        body:  { query: { knn: hash_including(filter: {
                                                bool: { filter: [
                                                  { term:  { object_name: 'KnowledgeBase::Answer::Translation' } },
                                                  { terms: { object_id: [1, 2] } }
                                                ] }
                                              }) } }
      )
    end
  end

  describe '.destroy' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }

    context 'when content is given' do
      let(:content) { 'test content' }

      context 'when document does not exist' do
        before do
          allow(instance).to receive(:client)
            .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
          allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
            .and_return(true)
          allow(instance.client).to receive_messages(exists?: false, delete: nil)
        end

        it 'returns nil' do
          expect(instance.destroy(object_id:, object_name:, content:)).to be_nil
        end
      end

      context 'when document exists' do
        before do
          allow(instance).to receive(:client)
            .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
          allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
            .and_return(true)
          allow(instance.client).to receive_messages(exists?: true, delete: true)
        end

        it 'deletes the document successfully' do
          expect(instance.destroy(object_id:, object_name:, content:)).to be_truthy
        end
      end
    end

    context 'when content is not given' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client))
        allow(instance.client).to receive(:delete_by_query).and_return(true)
      end

      it 'deletes all entries matching object_id and object_name' do
        instance.destroy(object_id:, object_name:)

        expect(instance.client).to have_received(:delete_by_query).with(
          index: instance.index_name,
          body:  {
            query: {
              bool: {
                filter: [
                  { term: { object_id:   object_id } },
                  { term: { object_name: object_name } }
                ]
              }
            }
          }
        )
      end
    end
  end

  describe '.upsert' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }
    let(:content)     { 'test content' }
    let(:embedding)   { [0.1, 0.2, 0.3] }
    let(:metadata)    { { key: 'value' } }

    context 'when index does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(false)
      end

      it 'raises AI::VectorDB::MigrationError' do
        expect { instance.upsert(object_id:, object_name:, content:, embedding:, metadata:) }
          .to raise_error(AI::VectorDB::MigrationError, 'Elasticsearch index does not exist')
      end
    end

    context 'when document already exists' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive_messages(exists?: true, index: true)
      end

      it 'does not create the document successfully' do
        expect(instance.upsert(object_id:, object_name:, content:, embedding:, metadata:)).to be_truthy
      end
    end

    context 'when document does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive_messages(exists?: false, index: true)
      end

      it 'creates the document successfully' do
        expect(instance.upsert(object_id:, object_name:, content:, embedding:, metadata:)).to be_truthy
      end
    end
  end

  describe '.bulk' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }
    let(:embedding)   { [0.1, 0.2, 0.3] }
    let(:client) do
      instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions))
    end

    before do
      allow(instance).to receive(:client).and_return(client)
      allow(client.indices).to receive(:exists?).with(index: instance.index_name).and_return(true)
      allow(client).to receive(:bulk).and_return(double(body: { 'errors' => false }))
    end

    it 'sends upserts and deletes as a single _bulk request' do
      instance.bulk(
        upserts: [{ object_id:, object_name:, content: 'chunk one', embedding:, metadata: { k: 'v' } }],
        deletes: ['ticket-1-stale'],
      )

      expect(client).to have_received(:bulk).once.with(
        index: instance.index_name,
        body:  [
          { index: { _id: "ticket-1-#{Digest::SHA256.hexdigest('chunk one')}" } },
          { content: 'chunk one', object_id:, object_name:, embedding:, metadata: { k: 'v' } },
          { delete: { _id: 'ticket-1-stale' } },
        ],
      )
    end

    it 'does nothing when there is nothing to write' do
      instance.bulk(upserts: [], deletes: [])

      expect(client).not_to have_received(:bulk)
    end

    it 'raises and logs only the failed items when the bulk response reports item errors', :aggregate_failures do
      items = [
        { 'index'  => { '_id' => 'ticket-1-ok', 'status' => 200 } },
        { 'delete' => { '_id' => 'ticket-1-stale', 'status' => 409, 'error' => { 'type' => 'version_conflict_engine_exception' } } },
      ]
      allow(client).to receive(:bulk).and_return(double(body: { 'errors' => true, 'items' => items }))
      logged = nil
      allow(Rails.logger).to receive(:error) { |&block| logged = block&.call }

      expect { instance.bulk(deletes: ['ticket-1-stale']) }.to raise_error(AI::VectorDB::Error)
      expect(logged).to include('ticket-1-stale')
      expect(logged).not_to include('ticket-1-ok')
    end
  end

  describe '.update_metadata' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }
    let(:metadata)    { { key: 'new_value' } }
    let(:client) do
      instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions))
    end

    before do
      allow(instance).to receive(:client).and_return(client)
      allow(client.indices).to receive(:exists?).with(index: instance.index_name).and_return(true)
      allow(client).to receive(:update_by_query).and_return(double(body: { 'updated' => 2, 'timed_out' => false, 'failures' => [] }))
    end

    it 'patches the metadata on every chunk of the document via update_by_query' do
      instance.update_metadata(object_id:, object_name:, metadata:)

      expect(client).to have_received(:update_by_query).once.with(
        index: instance.index_name,
        body:  {
          query:  { bool: { filter: [{ term: { object_id: } }, { term: { object_name: } }] } },
          script: { source: 'ctx._source.metadata = params.metadata', params: { metadata: } }
        }
      )
    end

    it 'raises when the response timed out' do
      allow(client).to receive(:update_by_query).and_return(double(body: { 'timed_out' => true, 'failures' => [] }))

      expect { instance.update_metadata(object_id:, object_name:, metadata:) }.to raise_error(AI::VectorDB::Error)
    end

    it 'raises when the response reports failures' do
      allow(client).to receive(:update_by_query).and_return(double(body: { 'timed_out' => false, 'failures' => [{ 'cause' => 'shard failure' }] }))

      expect { instance.update_metadata(object_id:, object_name:, metadata:) }.to raise_error(AI::VectorDB::Error)
    end
  end

  describe '.update' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }
    let(:content)     { 'updated content' }
    let(:embedding)   { [0.4, 0.5, 0.6] }
    let(:metadata)    { { key: 'new_value' } }

    context 'when index does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(false)
      end

      it 'raises AI::VectorDB::MigrationError' do
        expect { instance.update(object_id:, object_name:, content:, embedding:, metadata:) }
          .to raise_error(AI::VectorDB::MigrationError, 'Elasticsearch index does not exist')
      end
    end

    context 'when document exists' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive_messages(update: true)
      end

      it 'updates the document successfully' do
        expect(instance.update(object_id:, object_name:, content:, embedding:, metadata:)).to be_truthy
      end
    end
  end
end
