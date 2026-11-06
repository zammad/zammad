# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::SearchKnowledgeBase::Coverage, :aggregate_failures do
  describe '.for' do
    it 'knows the values of a measured embedding model, whichever provider serves it' do
      expect(described_class.for('bge-m3')).to have_attributes(listed: 0.78, covered: 0.80, margin: 0.01)
      expect(described_class.for('bge-m3:latest')).to have_attributes(listed: 0.78, covered: 0.80, margin: 0.01)
    end

    it 'gives none for a model nobody measured' do
      expect(described_class.for('text-embedding-3-small')).to be_nil
      expect(described_class.for(nil)).to be_nil
    end
  end

  describe '#of' do
    subject(:coverage) { described_class.for('bge-m3') }

    it 'is covered when the best answer reaches the upper value and is the only one' do
      expect(coverage.of([0.81])).to eq('covered')
    end

    it 'is covered when the best answer stands out by the margin' do
      expect(coverage.of([0.79, 0.85])).to eq('covered')
    end

    it 'is weak when the best answers are about equally close' do
      expect(coverage.of([0.85, 0.845])).to eq('weak')
    end

    it 'is weak when no answer reaches the upper value' do
      expect(coverage.of([0.79])).to eq('weak')
    end

    it 'is none without answers' do
      expect(coverage.of([])).to eq('none')
    end
  end
end
