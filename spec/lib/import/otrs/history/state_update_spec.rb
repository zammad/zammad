# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/history_examples'

RSpec.describe Import::OTRS::History::StateUpdate do
  it_behaves_like 'Import::OTRS::History'

  it 'imports an OTRS StateUpdate history entry' do

    zammad_structure = {
      id:                '11305',
      o_id:              '730',
      history_type:      'updated',
      history_object:    'Ticket',
      history_attribute: 'state',
      value_from:        'new',
      id_from:           1,
      value_to:          'open',
      id_to:             2,
      created_at:        '2014-11-21 00:21:08',
      created_by_id:     '3'
    }

    history_from_json('state_update/default', zammad_structure)
  end
end
