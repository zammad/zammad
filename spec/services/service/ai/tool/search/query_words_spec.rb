# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Search::QueryWords do
  it 'keeps the words and leaves out Elasticsearch\'s query syntax', :aggregate_failures do
    expect(described_class.without_syntax('outlook sync "after" update')).to eq('outlook sync after update')
    expect(described_class.without_syntax('ERR-4032 v2.1 anna@example.com')).to eq('ERR-4032 v2.1 anna@example.com')
    expect(described_class.without_syntax('_exists_:title -spam AND ham')).to eq('_exists_ title spam ham')
  end

  it 'finds a word to look for only where something else than syntax and the database\'s wildcards is left', :aggregate_failures do
    expect(['%', '_', '%%', '% _', '? %'].map { |text| described_class.words?(text) }).to all(be(false))
    expect(['50%', 'user_name', 'ERR-4032'].map { |text| described_class.words?(text) }).to all(be(true))
  end

  it 'finds a word in a quoted phrase, also where it is an operator', :aggregate_failures do
    expect(['"OR"', '"printer offline"'].map { |text| described_class.words?(text) }).to all(be(true))
    expect(['""', '"" OR ""', '"*"'].map { |text| described_class.words?(text) }).to all(be(false))
  end

  it 'finds a field with its value, not a colon in a sentence, a time or a link', :aggregate_failures do
    expect(['title:printer', 'created_at:>now-1d', 'article.body:"error"'].map { |text| described_class.field?(text) }).to all(be(true))
    expect(['printer: offline', 'meeting at 10:30', 'https://portal.example.com', 'outlook'].map { |text| described_class.field?(text) }).to all(be(false))
  end

  it 'leaves nothing of a text that is nothing but syntax' do
    expect(['?', '*', '* ?', '(*)', '\\*', '*:*', 'AND', '"" OR ""'].map { |text| described_class.without_syntax(text) }).to all(be_empty)
  end
end
