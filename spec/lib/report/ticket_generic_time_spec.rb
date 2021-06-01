# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Report::TicketGenericTime do

=begin

  result = Report::TicketGenericTime.items(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { field: 'created_at' },
  )

returns

  {
    count: 123,
    ticket_ids: [4,5,1,5,0,51,5,56,7,4],
    assets: assets,
  }

=end

  describe 'items' do

    # Regression test for issue #2246 - Records in Reporting not updated when single ActiveRecord can not be found
    it 'correctly handles missing tickets' do
      class_double('SearchIndexBackend', selectors: { ticket_ids: [-1] } ).as_stubbed_const

      expect do
        described_class.items(
          range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
          range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
          selector:    {}, # ticket selector to get only a collection of tickets
          params:      { field: 'created_at' },
        )
      end.not_to raise_error
    end
  end
end
