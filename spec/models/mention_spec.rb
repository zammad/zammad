# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:ticket) { create(:ticket) }
  let(:user)   { create(:agent_and_customer, groups: [ticket.group]) }

  describe 'validation' do
    it 'does not allow mentions for customers' do
      record = build(:mention, mentionable: ticket, user: create(:customer))
      record.save

      expect(record.errors.full_messages).to include('A mentioned user has no agent access to this ticket')
    end
  end

  describe '.subscribed?', current_user_id: 1 do
    it 'returns true when subscribed' do
      described_class.subscribe! ticket, user

      expect(described_class).to be_subscribed(ticket, user)
    end

    it 'returns false when subscribed' do
      expect(described_class).not_to be_subscribed(ticket, user)
    end
  end

  describe '.subscribe!', current_user_id: 1 do
    it 'subscribes to a object' do
      expect { described_class.subscribe! ticket, user }
        .to change { ticket.mentions.where(user: user).count }
        .from(0)
        .to(1)
    end

    it 'ignores if re-subscribing to a object' do
      described_class.subscribe! ticket, user

      expect { described_class.subscribe! ticket, user }
        .not_to change { ticket.mentions.where(user: user).count }
        .from(1)
    end
  end

  describe '.unsubscribe!', current_user_id: 1 do
    it 'unsubscribes from a object' do
      described_class.subscribe! ticket, user

      expect { described_class.unsubscribe! ticket, user }
        .to change { ticket.mentions.where(user: user).count }
        .from(1)
        .to(0)
    end

    it 'ignores if unsubscribing from a not-subscribed object' do
      expect(described_class.unsubscribe!(ticket, user))
        .to be_truthy
    end
  end

  describe '.unsubscribe_all!', current_user_id: 1 do
    it 'unsubscribes all users from a object' do
      described_class.subscribe! ticket, user
      described_class.subscribe! ticket, create(:agent_and_customer, groups: [ticket.group])

      expect { described_class.unsubscribe_all! ticket }
        .to change { ticket.mentions.count }
        .by(-2)
    end

    it 'ignores if unsubscribing from a not-subscribed object' do
      expect(described_class.unsubscribe!(ticket, user))
        .to be_truthy
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
