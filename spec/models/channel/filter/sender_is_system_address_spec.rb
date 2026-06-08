# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::SenderIsSystemAddress, type: :channel_filter do
  context 'when x-zammad-article-sender is present' do
    let(:mail_hash) { { 'x-zammad-article-sender': 'test' } }

    it 'does nothing' do
      expect { filter(mail_hash) }.not_to change { mail_hash }
    end
  end

  context 'when x-zammad-ticket-create-article-sender is present' do
    let(:mail_hash) { { 'x-zammad-ticket-create-article-sender': 'test' } }

    it 'does nothing' do
      expect { filter(mail_hash) }.not_to change { mail_hash }
    end
  end

  context 'when sent from the address that is not in the system' do
    let(:mail_hash) { { from_email: Faker::Internet.unique.email } }

    it 'does nothing' do
      expect { filter(mail_hash) }.not_to change { mail_hash }
    end
  end

  context 'when sent from the system address' do
    let(:email) { Faker::Internet.unique.email }
    let(:email_address) { create(:email_address, email:) }
    let(:mail_hash)     { { from_email: email } }

    it 'does nothing' do
      email_address

      expect { filter(mail_hash) }.not_to change { mail_hash }
    end
  end

  context 'when sent by non-agent' do
    let(:email) { Faker::Internet.unique.email }
    let(:customer)  { create(:customer, email:) }
    let(:mail_hash) { { from_email: email } }

    it 'does nothing' do
      expect { filter(mail_hash) }.not_to change { mail_hash }
    end
  end

  context 'when sent by an agent' do
    let(:group)  { create(:group) }
    let(:ticket) { nil }

    let(:mail_hash) do
      {
        'raw-from':                 agent.email,
        from_email:                 agent.email,
        to:                         Faker::Internet.unique.email,
        'x-zammad-ticket-group_id': group.id,
        'x-zammad-ticket-id':       ticket&.id
      }.compact
    end

    context 'when agent has access to the destination group' do
      let(:agent) { create(:agent, groups: [group]) }

      it 'sets both to agent' do
        filter(mail_hash)

        expect(mail_hash).to include(
          'x-zammad-article-sender':               'Agent',
          'x-zammad-ticket-create-article-sender': 'Agent'
        )
      end

      context 'when corresponding ticket exists and agent-customer is set as customer of it' do
        let(:ticket) { create(:ticket, customer: agent, group:) }

        it 'sets both to customer' do
          filter(mail_hash)

          expect(mail_hash).to include(
            'x-zammad-article-sender':               'Customer',
            'x-zammad-ticket-create-article-sender': 'Customer'
          )
        end
      end

      context 'when agent is a customer in the destination group' do
        let(:agent) { create(:agent) }

        it 'x-zammad-ticket-create-article-sender to agent but skips x-zammad-article-sender' do
          filter(mail_hash)

          expect(mail_hash)
            .to include('x-zammad-ticket-create-article-sender': 'Agent')
            .and(not_include('x-zammad-article-sender'))
        end
      end
    end
  end
end
