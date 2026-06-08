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

    context 'when no document is found' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive_messages(exists?: false, get: nil)
      end

      it 'returns nil' do
        expect(instance.find(object_id:, object_name:)).to be_nil
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
        expect(instance.find(object_id:, object_name:)).to eq(document)
      end
    end
  end

  describe '.destroy' do
    let(:object_id)   { 1 }
    let(:object_name) { 'ticket' }

    context 'when document does not exist' do
      before do
        allow(instance).to receive(:client)
          .and_return(instance_double(Elasticsearch::Client, indices: instance_double(Elasticsearch::API::Indices::Actions)))
        allow(instance.client.indices).to receive(:exists?).with(index: instance.index_name)
          .and_return(true)
        allow(instance.client).to receive_messages(exists?: false, delete: nil)
      end

      it 'returns nil' do
        expect(instance.destroy(object_id:, object_name:)).to be_nil
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
        expect(instance.destroy(object_id:, object_name:)).to be_truthy
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
