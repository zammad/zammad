# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/report_examples'

RSpec.describe Report::TicketBacklog, searchindex: true do
  include_examples 'with report examples'

  describe '.aggs' do
    it 'passes current user to SearchIndexBackend' do
      user = create(:user)

      allow(SearchIndexBackend).to receive(:selectors).and_call_original

      described_class.aggs(
        range_start:  Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:    Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:     'month', # year, quarter, month, week, day, hour, minute, second
        selector:     {}, # ticket selector to get only a collection of tickets
        params:       { field: 'created_at' },
        current_user: user
      )

      expect(SearchIndexBackend)
        .to have_received(:selectors)
        .with(anything, anything, hash_including(current_user: user), anything)
        .twice
    end
  end
end
