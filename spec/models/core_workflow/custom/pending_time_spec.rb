# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::PendingTime, mariadb: true, type: :model do
  include_context 'with core workflow base'

  it 'does not show pending time for non pending state' do
    expect(result[:visibility]['pending_time']).to eq('remove')
  end

  describe 'for ticket id with no state change' do
    let(:payload) do
      base_payload.merge('params' => {
                           'id' => ticket.id,
                         })
    end

    it 'does show pending time for pending ticket' do
      expect(result[:visibility]['pending_time']).to eq('show')
    end
  end

  describe 'for ticket id with state change' do
    let(:payload) do
      base_payload.merge('params' => {
                           'id'       => ticket.id,
                           'state_id' => Ticket::State.find_by(name: 'open').id.to_s,
                         })
    end

    it 'does not show pending time for pending ticket' do
      expect(result[:visibility]['pending_time']).to eq('remove')
    end
  end
end
