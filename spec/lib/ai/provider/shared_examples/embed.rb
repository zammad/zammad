# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'provider/embed' do |dimensions:|
  describe '#embed' do
    let(:dimensions) { dimensions }

    context 'when embeddings are requested' do
      it 'returns embeddings', aggregate_failures: true do
        response = ai_provider.embed(input: 'this is sample input')

        expect(response.size).to eq(dimensions)
        expect(response).to all(be_a(Float))
      end
    end
  end

  describe '#bulk_embed' do
    let(:dimensions) { dimensions }

    context 'when embeddings are requested' do
      let(:input) { ['this is sample input', 'this is another sample input', '3rd option'] }

      it 'returns embeddings', aggregate_failures: true do
        response = ai_provider.bulk_embed(input:)

        expect(response.size).to eq(3)
        expect(response).to all(have_attributes(size: eq(dimensions)))
        expect(response).to all(all(be_a(Float)))
      end
    end
  end
end

RSpec.shared_examples 'provider/embed_not_implemented' do
  describe '#embed' do
    context 'when embeddings are requested' do
      it 'raises an error' do
        expect { ai_provider.embed(input: 'test') }.to raise_error(NotImplementedError, 'not implemented yet due to missing API')
      end
    end
  end

  describe '#bulk_embed' do
    context 'when embeddings are requested' do
      it 'raises an error' do
        expect { ai_provider.bulk_embed(input: 'test') }.to raise_error(NotImplementedError, 'not implemented yet due to missing API')
      end
    end
  end
end
