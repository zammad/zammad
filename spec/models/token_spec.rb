require 'rails_helper'

RSpec.describe Token, type: :model do
  subject(:token) { create(:password_reset_token) }

  describe '.check' do
    context 'with name and action matching existing token' do
      it 'returns the token’s user' do
        expect(described_class.check(action: token.action, name: token.name)).to eq(token.user)
      end
    end

    context 'with invalid name' do
      it 'returns nil' do
        expect(described_class.check(action: token.action, name: '1NV4L1D')).to be(nil)
      end
    end

    context 'with invalid action' do
      it 'returns nil' do
        expect(described_class.check(action: 'PasswordReset_NotExisting', name: token.name)).to be(nil)
      end
    end

    describe 'persistence handling' do
      context 'for persistent token' do
        subject(:token) { create(:ical_token, persistent: true, created_at: created_at) }

        context 'at any time' do
          let(:created_at) { 1.month.ago }

          it 'returns the token’s user' do
            expect(described_class.check(action: token.action, name: token.name)).to eq(token.user)
          end

          it 'does not delete the token' do
            token  # create token

            expect { described_class.check(action: token.action, name: token.name) }
              .not_to change(described_class, :count)
          end
        end
      end

      context 'for non-persistent token' do
        subject(:token) { create(:password_reset_token, persistent: false, created_at: created_at) }

        context 'less than one day after creation' do
          let(:created_at) { 1.day.ago + 5 }

          it 'returns the token’s user' do
            expect(described_class.check(action: token.action, name: token.name)).to eq(token.user)
          end

          it 'does not delete the token' do
            token  # create token

            expect { described_class.check(action: token.action, name: token.name) }
              .not_to change(described_class, :count)
          end
        end

        context 'at least one day after creation' do
          let(:created_at) { 1.day.ago }

          it 'returns nil' do
            expect(described_class.check(action: token.action, name: token.name)).to be(nil)
          end

          it 'deletes the token' do
            token  # create token

            expect { described_class.check(action: token.action, name: token.name) }
              .to change(described_class, :count).by(-1)
          end
        end
      end
    end

    describe 'permission matching' do
      subject(:token) { create(:api_token, user: agent, preferences: preferences) }

      let(:agent) { create(:agent_user) }
      let(:preferences) { { permission: %w[admin ticket.agent] } } # agent has no access to admin.*

      context 'with a permission shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'ticket.agent')).to eq(agent)
        end
      end

      context 'with the child of a permission shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'ticket.agent.foo')).to eq(agent)
        end
      end

      context 'with the parent of a permission shared by both token.user and token.preferences' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'ticket')).to be(nil)
        end
      end

      context 'with a permission in token.preferences, but not on token.user' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'admin')).to be(nil)
        end
      end

      context 'with a permission not in token.preferences, but on token.user' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'cti.agent')).to be(nil)
        end
      end

      context 'with non-existent permission' do
        it 'returns nil' do
          expect(described_class.check(action: token.action, name: token.name, permission: 'foo')).to be(nil)
        end
      end

      context 'with multiple permissions, where at least one is shared by both token.user and token.preferences' do
        it 'returns token.user' do
          expect(described_class.check(action: token.action, name: token.name, permission: %w[foo ticket.agent])).to eq(agent)
        end
      end
    end
  end

  describe 'Attributes:' do
    describe '#persistent' do
      context 'when not set on creation' do
        subject(:token) { described_class.create(action: 'foo', user_id: User.first.id) }

        it 'defaults to nil' do
          expect(token.persistent).to be(nil)
        end
      end
    end
  end
end
