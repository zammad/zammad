# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/history_examples'

RSpec.describe Import::OTRS::History::NewTicket do
  it_behaves_like 'Import::OTRS::History'

  it 'imports an OTRS NewTicket history entry' do

    zammad_structure = {
      id:             '11291',
      o_id:           '730',
      history_type:   'created',
      history_object: 'Ticket',
      created_at:     '2014-11-21 00:17:41',
      created_by_id:  '3'
    }

    history_from_json('new_ticket/default', zammad_structure)
  end
end
