# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::ExternalReferences::Snipeit::LinkAssets do
  subject(:service) { described_class.with_current_user(agent) }

  let(:agent)  { create(:agent, groups: [ticket.group]) }
  let(:ticket) { create(:ticket) }

  let(:asset_26) { { 'id' => 26, 'name' => 'Laptop-001', 'asset_tag' => 'LAP001' } }
  let(:asset_27) { { 'id' => 27, 'name' => 'Monitor-002', 'asset_tag' => 'MON002' } }

  before do
    Setting.set('snipeit_integration', true)
    allow(Snipeit).to receive(:asset).with(26).and_return(asset_26)
    allow(Snipeit).to receive(:asset).with(27).and_return(asset_27)
  end

  def snipeit_history
    ticket.reload.history_get.select { |entry| entry['attribute'] == 'snipeit' }
  end

  it 'stores the asset ids on the ticket' do
    service.execute(ticket: ticket, asset_ids: [26, 27])

    expect(ticket.reload.preferences[:snipeit][:asset_ids]).to eq([26, 27])
  end

  it 'normalizes and deduplicates the given ids' do
    service.execute(ticket: ticket, asset_ids: [26, '26', 27])

    expect(ticket.reload.preferences[:snipeit][:asset_ids]).to eq([26, 27])
  end

  it 'records an added history entry per newly linked asset', aggregate_failures: true do
    service.execute(ticket: ticket, asset_ids: [26])

    expect(snipeit_history.length).to eq(1)
    expect(snipeit_history.first).to include('type' => 'added', 'value_to' => 'LAP001')
  end

  it 'attributes the history entry to the acting user' do
    service.execute(ticket: ticket, asset_ids: [26])

    expect(snipeit_history.first['created_by_id']).to eq(agent.id)
  end

  context 'when assets are already linked' do
    before do
      service.execute(ticket: ticket, asset_ids: [26, 27])
    end

    it 'records only the removal when an asset is unlinked', aggregate_failures: true do
      service.execute(ticket: ticket.reload, asset_ids: [26])

      removals = snipeit_history.select { |entry| entry['type'] == 'removed' }
      expect(removals.length).to eq(1)
      expect(removals.first['value_to']).to eq('MON002')
    end

    it 'records nothing when the asset ids are unchanged' do
      entries_before = snipeit_history.length

      service.execute(ticket: ticket.reload, asset_ids: [26, 27])

      expect(snipeit_history.length).to eq(entries_before)
    end

    it 'records both sides when an asset is swapped', aggregate_failures: true do
      service.execute(ticket: ticket.reload, asset_ids: [27])

      expect(snipeit_history.pluck('type')).to include('added', 'removed')
      expect(ticket.reload.preferences[:snipeit][:asset_ids]).to eq([27])
    end
  end

  context 'when the asset can no longer be fetched from Snipe-IT' do
    before do
      allow(Snipeit).to receive(:asset).with(26).and_raise('API down')
    end

    # A broken Snipe-IT connection must not stop the ticket from being saved.
    it 'falls back to the bare id and still stores the link', aggregate_failures: true do
      service.execute(ticket: ticket, asset_ids: [26])

      expect(ticket.reload.preferences[:snipeit][:asset_ids]).to eq([26])
      expect(snipeit_history.first['value_to']).to eq('26')
    end
  end

  it 'requires a current user' do
    expect { described_class.execute(ticket: ticket, asset_ids: [26]) }
      .to raise_error(%r{Current user is required})
  end
end
