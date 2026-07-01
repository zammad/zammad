# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache do
  let(:ticket)              { create(:ticket) }
  let(:locale)              { 'en-us' }
  let(:embedding_source)    { :auto }
  let(:embedding)           { [0.1, 0.2, 0.3] }

  it 'stores and looks up the embedding for the ticket, embedding source and locale' do
    described_class.store(ticket:, embedding_source:, locale:, embedding:)

    expect(described_class.lookup(ticket:, embedding_source:, locale:)).to eq(embedding)
  end

  it 'is a miss once a new article changes the version' do
    described_class.store(ticket:, embedding_source:, locale:, embedding:)
    create(:ticket_article, ticket:)

    expect(described_class.lookup(ticket:, embedding_source:, locale:)).to be_nil
  end

  it 'is a miss for a different embedding source' do
    described_class.store(ticket:, embedding_source: :auto, locale:, embedding:)

    expect(described_class.lookup(ticket:, embedding_source: :summary, locale:)).to be_nil
  end

  it 'is a miss for a different locale' do
    described_class.store(ticket:, embedding_source:, locale: 'en-us', embedding:)

    expect(described_class.lookup(ticket:, embedding_source:, locale: 'de-de')).to be_nil
  end

  it 'is a miss when nothing is stored' do
    expect(described_class.lookup(ticket:, embedding_source:, locale:)).to be_nil
  end
end
