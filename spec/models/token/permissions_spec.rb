# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Token::Permissions, type: :model do
  let(:user)  { create(:agent) }
  let(:token) { create(:token, user:, preferences: { permission: ['ticket.agent', 'admin.users'] }) }

  describe '#permissions?' do
    it 'returns value from Auth::Permissions' do
      allow(Auth::Permissions).to receive(:authorized?).and_return(true)
      token.permissions?('ticket.agent')
      expect(Auth::Permissions).to have_received(:authorized?).with(token, 'ticket.agent')
    end

    it 'returns false if user does not have permission' do
      expect(token).not_to be_permissions('foo')
    end

    it 'returns false if token does not have permission' do
      expect(token).not_to be_permissions('user_preferences')
    end

    it 'returns true if both user and token has permission' do
      expect(token).to be_permissions('ticket.agent')
    end
  end

  describe '#permissions!' do
    it 'raises error if user does not have permission' do
      expect { token.permissions!('foo') }.to raise_error('Token authorization failed.')
    end

    it 'returns true if token has permission' do
      expect(user).to be_permissions('ticket.agent')
    end
  end

  describe '#permissions' do
    it 'returns permissions' do
      expect(token.permissions.pluck(:name)).to eq(['ticket.agent'])
    end
  end
end
