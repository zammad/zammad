# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::KnowledgeBase::IconSetType do
  context 'when receiving an icon set' do
    it 'accepts every icon set the model allows' do
      expect(KnowledgeBase::ICONSETS.map { |iconset| described_class.coerce_input(iconset) })
        .to eq(KnowledgeBase::ICONSETS)
    end

    it 'keeps dashes intact' do
      expect(described_class.coerce_input('Simple-Line-Icons')).to eq('Simple-Line-Icons')
    end

    it 'raises an error for an unknown icon set' do
      expect { described_class.coerce_input('Nonexisting') }.to raise_error(GraphQL::CoercionError)
    end

    it 'raises an error for a differently cased icon set' do
      expect { described_class.coerce_input('fontawesome') }.to raise_error(GraphQL::CoercionError)
    end
  end

  context 'when sending an icon set' do
    it 'passes a valid icon set through unchanged' do
      expect(described_class.coerce_result('FontAwesome')).to eq('FontAwesome')
    end

    it 'raises an error for an unknown icon set' do
      expect { described_class.coerce_result('Nonexisting') }.to raise_error(GraphQL::CoercionError)
    end
  end
end
