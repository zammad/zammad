# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Token, type: :model do
  subject(:token) { create(:password_reset_token, user: user) }

  let(:user) { create(:user) }

  describe '.check' do
    context 'with name and action matching existing token' do
      it 'returns the token’s user' do
        expect(described_class.check(action: token.action, token: token.token)).to eq(token.user)
      end
    end

    context 'with invalid name' do
      it 'returns nil' do
        expect(described_class.check(action: token.action, token: '1NV4L1D')).to be_nil
      end
    end

    context 'with invalid action' do
      it 'returns nil' do
        expect(described_class.check(action: 'PasswordReset_NotExisting', token: token.token)).to be_nil
      end
    end

    describe 'persistence handling' do
      context 'for persistent token' do
        subject(:token) { create(:ical_token, persistent: true, created_at: created_at) }

        context 'at any time' do
          let(:created_at) { 1.month.ago }

          it 'returns the token’s user' do
            expect(described_class.check(action: token.action, token: token.token)).to eq(token.user)
          end

          it 'does not delete the token' do
            token  # create token

            expect { described_class.check(action: token.action, token: token.token) }
              .not_to change(described_class, :count)
          end
        end
      end

      context 'for non-persistent token' do
        subject(:token) { create(:password_reset_token, persistent: false, created_at: created_at) }

        context 'less than one day after creation' do
          let(:created_at) { 1.day.ago + 5 }

          it 'returns the token’s user' do
            expect(described_class.check(action: token.action, token: token.token)).to eq(token.user)
          end

          it 'does not delete the token' do
            token  # create token

            expect { described_class.check(action: token.action, token: token.token) }
              .not_to change(described_class, :count)
          end
        end

        context 'at least one day after creation' do
          let(:created_at) { 1.day.ago }

          it 'returns nil' do
            expect(described_class.check(action: token.action, token: token.token)).to be_nil
          end

          it 'deletes the token' do
            token  # create token

            expect { described_class.check(action: token.action, token: token.token) }
              .to change(described_class, :count).by(-1)
          end
        end
      end
    end

    describe 'permission matching' do
      subject(:token) { create(:api_token, user: agent, preferences: preferences) }

      let(:agent)       { create(:agent) }
      let(:preferences) { { permission: %w[admin ticket.agent] } } # agent has no access to admin.*

      context 'with a permission shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, token: token.token, permission: 'ticket.agent')).to eq(agent)
        end
      end

      context 'with the child of a permission shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, token: token.token, permission: 'ticket.agent.foo')).to eq(agent)
        end
      end

      context 'with the parent of a permission shared by both token.user and token.preferences' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, token: token.token, permission: 'ticket')).to be_nil
        end
      end

      context 'with a permission in token.preferences, but not on token.user' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, token: token.token, permission: 'admin')).to be_nil
        end
      end

      context 'with a permission not in token.preferences, but on token.user' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, token: token.token, permission: 'cti.agent')).to be_nil
        end
      end

      context 'with non-existent permission' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, token: token.token, permission: 'foo')).to be_nil
        end
      end

      context 'with multiple permissions, where at least one is shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, token: token.token, permission: %w[foo ticket.agent])).to eq(agent)
        end
      end
    end
  end

  describe '#fetch' do
    it 'returns nil when not present' do
      expect(described_class.fetch('token', user)).to be_nil
    end

    it 'returns token when present' do
      token

      expect(described_class.fetch(token.action, token.user.id)).to eq(token)
    end
  end

  describe '.ensure_token!' do
    it 'returns token when not present' do
      expect(described_class.ensure_token!('token', user.id)).to be_present
    end

    it 'returns token when present' do
      token

      expect(described_class.ensure_token!(token.action, token.user.id)).to eq(token.token)
    end

    describe 'with persistent argument' do
      it 'creates not-persistent token if argument omitted' do
        described_class.ensure_token!('token', user.id)
        expect(described_class.find_by(action: 'token')).not_to be_persistent
      end

      it 'creates persistent token when flag given' do
        described_class.ensure_token!('token', user.id, persistent: true)
        expect(described_class.find_by(action: 'token')).to be_persistent
      end
    end
  end

  describe '#renew_token!' do
    it 'changes token' do
      expect { token.renew_token! }.to change { token.reload.token }
    end
  end

  describe '.renew_token!' do
    it 'creates token when not present' do
      expect(described_class.renew_token!('token', user.id)).to be_present
    end

    it 'returns token when present' do
      token

      expect { described_class.renew_token!(token.action, token.user.id) }.to change { token.reload.token }
    end

    describe 'with persistent argument' do
      it 'creates not-persistent token if argument omitted' do
        described_class.renew_token!('token', user.id)

        expect(described_class.find_by(action: 'token')).not_to be_persistent
      end

      it 'creates persistent token when flag given' do
        described_class.renew_token!('token', user.id, persistent: true)

        expect(described_class.find_by(action: 'token')).to be_persistent
      end
    end
  end

  describe '#visible_in_frontend?' do
    it 'persistent api token is visible in frontend' do
      token = create(:token)

      expect(token).to be_visible_in_frontend
    end

    it 'persistent non-api token is not visible in frontend' do
      token = create(:token, action: :nonapi)

      expect(token).not_to be_visible_in_frontend
    end

    it 'non-persistent api token is not visible in frontend' do
      token = create(:token, persistent: false)

      expect(token).not_to be_visible_in_frontend
    end
  end

  describe '#trigger_user_subscription' do
    it 'triggers subscription when token is created' do
      allow(Gql::Subscriptions::User::Current::AccessTokenUpdates).to receive(:trigger)

      create(:token)

      expect(Gql::Subscriptions::User::Current::AccessTokenUpdates).to have_received(:trigger)
    end

    it 'triggers subscription when token is destroyed' do
      token = create(:token)

      allow(Gql::Subscriptions::User::Current::AccessTokenUpdates).to receive(:trigger)

      token.destroy

      expect(Gql::Subscriptions::User::Current::AccessTokenUpdates).to have_received(:trigger)
    end

    it 'does not trigger subscription when token is updated' do
      token = create(:token)

      allow(Gql::Subscriptions::User::Current::AccessTokenUpdates).to receive(:trigger)

      token.touch

      expect(Gql::Subscriptions::User::Current::AccessTokenUpdates).not_to have_received(:trigger)
    end

    it 'does not trigger subscription when non-api token is created' do
      allow(Gql::Subscriptions::User::Current::AccessTokenUpdates).to receive(:trigger)

      create(:token, action: :nonapi)

      expect(Gql::Subscriptions::User::Current::AccessTokenUpdates).not_to have_received(:trigger)
    end
  end

  describe '.cleanup' do
    context 'when token is non persistent and old' do
      let(:token) { create(:token, persistent: false, created_at: 1.year.ago) }

      it 'is removed' do
        expect { described_class.cleanup }
          .to change { described_class.exists? token.id }
          .to false
      end
    end

    context 'when token is non persistent and fresh' do
      let(:token) { create(:token, persistent: false, created_at: 1.day.ago) }

      it 'is not removed' do
        expect { described_class.cleanup }
          .not_to change { described_class.exists? token.id }
          .from true
      end
    end

    context 'when token is persistent and old' do
      let(:token) { create(:token, persistent: true, created_at: 1.day.ago) }

      it 'is not removed' do
        expect { described_class.cleanup }
          .not_to change { described_class.exists? token.id }
          .from true
      end
    end
  end
end
