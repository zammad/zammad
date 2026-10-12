# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::HistoryFactory do
  describe '.skip?' do
    it 'imports supported history types' do
      %w[NewTicket StateUpdate Move PriorityUpdate].each do |type|
        expect(described_class.skip?({ 'HistoryType' => type })).to be false
      end
    end

    it 'imports unsupported history types that belong to an article' do
      expect(described_class.skip?({ 'HistoryType' => 'SendAnswer', 'ArticleID' => '42' })).to be false
    end

    it 'skips unsupported history types without an article', :aggregate_failures do
      expect(described_class.skip?({ 'HistoryType' => 'SendAnswer' })).to be true
      expect(described_class.skip?({ 'HistoryType' => 'SendAnswer', 'ArticleID' => '0' })).to be true
    end
  end

  describe '.backend_class' do
    it 'returns the history class of a supported history type', :aggregate_failures do
      expect(described_class.backend_class({ 'HistoryType' => 'NewTicket' })).to eq(Import::OTRS::History::NewTicket)
      expect(described_class.backend_class({ 'HistoryType' => 'StateUpdate' })).to eq(Import::OTRS::History::StateUpdate)
      expect(described_class.backend_class({ 'HistoryType' => 'Move' })).to eq(Import::OTRS::History::Move)
      expect(described_class.backend_class({ 'HistoryType' => 'PriorityUpdate' })).to eq(Import::OTRS::History::PriorityUpdate)
    end

    it 'returns the article history class for other history types with an article' do
      expect(described_class.backend_class({ 'HistoryType' => 'SendAnswer', 'ArticleID' => '42' })).to eq(Import::OTRS::History::Article)
    end

    it 'prefers the history type over the article' do
      expect(described_class.backend_class({ 'HistoryType' => 'Move', 'ArticleID' => '42' })).to eq(Import::OTRS::History::Move)
    end
  end
end
