# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::IdentifyGroup, type: :channel_filter do
  let(:group)  { create(:group) }
  let(:ticket) { create(:ticket, group:) }

  context 'when group is already present', :aggregate_failures do
    let(:group) { create(:group) }

    before do
      allow(described_class).to receive(:pick_group)
      allow(described_class).to receive(:find_existing_ticket)

      group
    end

    context 'when group id is present' do
      let(:mail_hash) { { 'x-zammad-ticket-group_id': group.id } }

      it 'does not do anything', :aggregate_failures do
        filter(mail_hash)

        expect(described_class).not_to have_received(:pick_group)
        expect(described_class).not_to have_received(:find_existing_ticket)
      end
    end

    context 'when group name is present' do
      let(:mail_hash) { { 'x-zammad-ticket-group': group.name } }

      it 'does not do anything', :aggregate_failures do
        filter(mail_hash)

        expect(described_class).not_to have_received(:pick_group)
        expect(described_class).not_to have_received(:find_existing_ticket)
      end
    end
  end

  context 'when ticket number is present' do
    let(:mail_hash) { { 'x-zammad-ticket-number': ticket.number } }

    it 'sets a group by ticket with the corresponding number' do
      filter(mail_hash)

      expect(mail_hash).to include('x-zammad-ticket-group_id': ticket.group_id)
    end
  end

  context 'when ticket ID is present' do
    let(:mail_hash) { { 'x-zammad-ticket-id': ticket.id } }

    it 'sets a group by ticket with the corresponding id' do
      filter(mail_hash)

      expect(mail_hash).to include('x-zammad-ticket-group_id': ticket.group_id)
    end
  end

  context 'when both ticket ID and number are present' do
    let(:mail_hash) do
      {
        'x-zammad-ticket-id':     create(:ticket).id,
        'x-zammad-ticket-number': ticket.number
      }
    end

    it 'sets a group by ticket with the corresponding number' do
      filter(mail_hash)

      expect(mail_hash).to include('x-zammad-ticket-group_id': ticket.group_id)
    end
  end

  context 'when no ticket identifier present but channel has a group' do
    let(:channel)   { create(:channel) }
    let(:mail_hash) { {} }

    it 'sets a group by the channel' do
      filter(mail_hash)

      expect(mail_hash).to include('x-zammad-ticket-group_id': channel.group_id)
    end
  end

  context 'when no ticket identifier and channel has no group' do
    let(:channel) { create(:channel, group_id: nil) }
    let(:other_channel) { create(:channel) }
    let(:email)         { Faker::Internet.unique.email }
    let(:mail_hash)     { { to: email } }
    let(:email_address) { create(:email_address, email:, channel: other_channel) }

    it 'sets a group by the target email' do
      filter(mail_hash, channel:)

      expect(mail_hash).to include('x-zammad-ticket-group_id': other_channel.group_id)
    end
  end

  context 'when group cannot be identified by ticket, channel or email to group mapping' do
    let(:mail_hash) { {} }

    it 'takes first group' do
      filter(mail_hash)

      expect(mail_hash).to include('x-zammad-ticket-group_id': Group.first.id)
    end
  end
end
