# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/history_examples'

RSpec.describe Import::OTRS::History::PriorityUpdate do
  it_behaves_like 'Import::OTRS::History'

  it 'imports an OTRS PriorityUpdate history entry' do

    zammad_structure = {
      id:                '11131',
      o_id:              '721',
      history_type:      'updated',
      history_object:    'Ticket',
      history_attribute: 'priority',
      value_from:        '2 low',
      value_to:          '4 high',
      id_from:           '2',
      id_to:             '4',
      created_at:        '2014-09-22 16:44:55',
      created_by_id:     '1'
    }

    history_from_json('priority_update/default', zammad_structure)
  end
end
