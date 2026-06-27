# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Embedding, :aggregate_failures do
  subject(:embedding) { described_class.execute(input:) }

  let(:provider) { instance_double(AI::Provider::OpenAI) }

  before do
    setup_ai_provider('open_ai')
    allow(AI::Provider).to receive(:current).and_return(AI::Provider::OpenAI)
    allow(AI::Provider::OpenAI).to receive(:new).and_return(provider)
  end

  context 'with an array input' do
    let(:input) { %w[one two] }

    it 'returns one vector per input' do
      allow(provider).to receive(:bulk_embed).and_return([[0.1], [0.2]])

      expect(embedding).to eq([[0.1], [0.2]])
    end

    it 'raises when the provider returns fewer vectors than inputs' do
      allow(provider).to receive(:bulk_embed).and_return([[0.1]])

      expect { embedding }.to raise_error(%r{returned 1 usable vectors for 2 inputs})
    end

    it 'raises when the provider returns a blank vector' do
      allow(provider).to receive(:bulk_embed).and_return([[0.1], []])

      expect { embedding }.to raise_error(%r{usable vectors})
    end

    it 'raises when the provider returns nil' do
      allow(provider).to receive(:bulk_embed).and_return(nil)

      expect { embedding }.to raise_error(%r{usable vectors})
    end

    it 'returns an empty array for empty input without calling the provider' do
      allow(provider).to receive(:bulk_embed)

      expect(described_class.execute(input: [])).to eq([])
      expect(provider).not_to have_received(:bulk_embed)
    end
  end

  context 'with a string input' do
    let(:input) { 'one' }

    it 'returns a single vector' do
      allow(provider).to receive(:embed).with(input:).and_return([0.1])

      expect(embedding).to eq([0.1])
    end
  end
end
