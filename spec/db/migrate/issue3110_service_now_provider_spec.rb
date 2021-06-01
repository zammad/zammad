# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3110ServiceNowProvider, type: :db_migration do

  let(:ticket) { create(:ticket) }
  let(:external_sync) do
    create(:external_sync,
           source:    'ServiceNow',
           source_id: 'INC678439',
           object:    'Ticket',
           o_id:      ticket.id)
  end

  before do
    create(:ticket_article,
           ticket:  ticket,
           subject: 'Incident INC678439 -- zugewiesen an EXT-XXXINIS',
           from:    'zam@mad-service-now.com')
  end

  it 'does migrates obsolete ServiceNow ExternalSync references' do
    expect { migrate }
      .to change { external_sync.reload.source }
      .from('ServiceNow')
      .to('ServiceNow-zam@mad-service-now.com')
  end
end
