# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:ticket) { create(:ticket) }
  let(:user)   { create(:agent_and_customer, groups: [ticket.group]) }

  describe 'validation' do
    it 'does not allow mentions for customers' do
      expect { create(:mention, mentionable: ticket, user: create(:customer)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: User has no ticket.agent permissions')
    end
  end

  describe '.mentionable?' do
    context 'with a ticket' do
      let(:other_ticket) { create(:ticket) }

      it 'retuns true if user has agent access' do
        expect(described_class).to be_mentionable(ticket, user)
      end

      it 'retuns true if user has limited agent access' do
        user.user_groups.create! group: other_ticket.group, access: 'read'

        expect(described_class).to be_mentionable(other_ticket, user)
      end

      it 'retuns false if agent has no access to this ticket' do
        expect(described_class).not_to be_mentionable(other_ticket, user)
      end

      it 'retuns false if user is customer' do
        ticket.update! customer: user

        expect(described_class).not_to be_mentionable(other_ticket, user)
      end
    end

    context 'with non-ticket' do
      it 'retuns false for non-Ticket' do
        expect(described_class).not_to be_mentionable(Ticket::Article.first, user)
      end
    end
  end
end
