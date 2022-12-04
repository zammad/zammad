# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:ticket) { create(:ticket) }
  let(:user)   { create(:agent)  }

  describe 'validation' do
    it 'does not allow mentions for customers' do
      expect { create(:mention, mentionable: ticket, user: create(:customer)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: User has no ticket.agent permissions')
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
end
