# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/history_examples'

RSpec.describe Import::OTRS::History::Article do
  it_behaves_like 'Import::OTRS::History'

  it 'imports an OTRS AddNote history entry' do

    zammad_structure = {
      id:                     '11307',
      o_id:                   '3973',
      history_type:           'created',
      history_object:         'Ticket::Article',
      related_o_id:           '730',
      related_history_object: 'Ticket',
      created_at:             '2014-11-21 00:21:08',
      created_by_id:          '3'
    }

    history_from_json('article/default', zammad_structure)
  end
end
