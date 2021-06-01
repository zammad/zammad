# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/history_examples'

RSpec.describe Import::OTRS::History::Move do
  it_behaves_like 'Import::OTRS::History'

  it 'imports an OTRS Move history entry' do

    zammad_structure = {
      id:                '238',
      o_id:              '39',
      history_type:      'updated',
      history_object:    'Ticket',
      history_attribute: 'group',
      value_from:        'Source',
      value_to:          'Target',
      id_from:           '5',
      id_to:             '2',
      created_at:        '2014-05-12 13:42:41',
      created_by_id:     '1'
    }

    history_from_json('move/default', zammad_structure)
  end
end
