# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Search::ResultWindow, :aggregate_failures do
  describe '.of' do
    it 'bounds a search on the index by the window configured for its model, and a search on the database not at all' do
      allow(SearchIndexBackend).to receive(:enabled?).and_return(true)

      expect(described_class.of(Ticket, query: 'printer')).to eq(SearchIndexBackend::MAX_RESULT_WINDOW)
      expect(described_class.of(Ticket, query: '*')).to be_nil

      Setting.set('es_model_settings', { 'Ticket' => { 'index.max_result_window' => 2_000_000 } })
      expect(described_class.of(Ticket, query: 'printer')).to eq(2_000_000)

      allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
      expect(described_class.of(Ticket, query: 'printer')).to be_nil
    end
  end

  describe '.fits?' do
    it 'fits a page and the record that tells whether more follow into the window' do
      expect(described_class.fits?(10, offset: 8, limit: 1)).to be(true)
      expect(described_class.fits?(10, offset: 9, limit: 1)).to be(false)
      expect(described_class.fits?(nil, offset: 10**12, limit: 50)).to be(true)
    end
  end

  describe '.more_text' do
    it 'names the cursor, the end of the matches, or the end of the window' do
      expect(described_class.more_text(has_more: true, next_cursor: 'abc')).to eq('More follow: call again with the same arguments and cursor "abc".')
      expect(described_class.more_text(has_more: false, next_cursor: nil)).to eq('No more follow.')
      expect(described_class.more_text(has_more: true, next_cursor: nil)).to eq('More follow, but the search pages no further. Narrow the query to see them.')
    end
  end
end
