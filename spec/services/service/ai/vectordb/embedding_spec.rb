# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Embedding, :aggregate_failures do
  subject(:embedding) { described_class.execute(input:) }

  let(:connection) { create(:ai_provider_connection, :default_embedding) }
  let(:provider)   { instance_double(AI::Provider::OpenAI) }

  before do
    allow(AI::ProviderConnection).to receive(:for_embeddings).and_return(connection)
    allow(connection).to receive(:provider_instance).and_return(provider)
  end

  context 'with an array input' do
    let(:input) { %w[one two] }

    it 'embeds them in one bulk_embed round-trip' do
      allow(provider).to receive(:bulk_embed).with(input:).and_return([[0.1], [0.2]])

      expect(embedding).to eq([[0.1], [0.2]])
      expect(provider).to have_received(:bulk_embed).once
    end

    it 'raises when the provider returns fewer vectors than inputs and records it on the connection' do
      allow(provider).to receive(:bulk_embed).and_return([[0.1]])

      expect { embedding }.to raise_error(AI::Provider::ResponseError, %r{returned 1 usable vectors for 2 inputs})
      expect(connection.reload.status).to include('state' => 'error', 'message' => include('1 usable vectors'))
    end

    it 'raises when the provider returns a blank vector' do
      allow(provider).to receive(:bulk_embed).and_return([[0.1], []])

      expect { embedding }.to raise_error(%r{usable vectors})
    end

    it 'raises when the provider returns nil' do
      allow(provider).to receive(:bulk_embed).and_return(nil)

      expect { embedding }.to raise_error(%r{usable vectors})
    end

    context 'with empty input' do
      let(:input) { [] }

      it 'returns an empty array without calling the provider' do
        allow(provider).to receive(:bulk_embed)

        expect(embedding).to eq([])
        expect(provider).not_to have_received(:bulk_embed)
      end
    end
  end

  context 'with a string input' do
    let(:input) { 'one' }

    it 'returns a single vector' do
      allow(provider).to receive(:embed).with(input:).and_return([0.1])

      expect(embedding).to eq([0.1])
    end

    it 'raises when the provider returns a blank vector and records it on the connection' do
      allow(provider).to receive(:embed).and_return(nil)

      expect { embedding }.to raise_error(AI::Provider::ResponseError, %r{no usable vector})
      expect(connection.reload.status).to include('state' => 'error', 'message' => include('no usable vector'))
    end
  end

  context 'when no embedding provider is configured' do
    let(:input) { 'x' }

    it 'raises' do
      allow(AI::ProviderConnection).to receive(:for_embeddings).and_return(nil)

      expect { embedding }.to raise_error(RuntimeError)
    end
  end
end
