# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::AfterAuth::DoorkeeperReturnTo do
  let(:user)    { create(:customer) }
  let(:session) { { doorkeeper_return_to: doorkeeper_return_to } }
  let(:options) { {} }

  describe '#run' do
    context 'when session has a valid doorkeeper return URL' do
      let(:doorkeeper_return_to) { '/oauth/authorize?client_id=abc&redirect_uri=http%3A%2F%2Flocalhost&response_type=code' }

      it 'returns the after auth type with the URL' do
        expect(described_class.run(user:, session:, options:)).to eq({
                                                                       type: 'DoorkeeperReturnTo',
                                                                       data: { url: doorkeeper_return_to },
                                                                     })
      end

      it 'removes the doorkeeper return URL from the session' do
        described_class.run(user:, session:, options:)
        expect(session).not_to have_key(:doorkeeper_return_to)
      end

      context 'when user has mandatory 2FA setup pending' do
        before do
          allow(user).to receive(:two_factor_setup_required?).and_return(true)
        end

        it 'returns nil to yield to TwoFactorConfiguration' do
          expect(described_class.run(user:, session:, options:)).to be_nil
        end

        it 'preserves the doorkeeper return URL in the session' do
          described_class.run(user:, session:, options:)
          expect(session[:doorkeeper_return_to]).to eq(doorkeeper_return_to)
        end
      end
    end

    context 'when session has no doorkeeper return URL' do
      let(:doorkeeper_return_to) { nil }

      it 'returns nil' do
        expect(described_class.run(user:, session:, options:)).to be_nil
      end
    end

    context 'when doorkeeper return URL does not start with /oauth/authorize' do
      let(:doorkeeper_return_to) { '/some/other/path' }

      it 'returns nil' do
        expect(described_class.run(user:, session:, options:)).to be_nil
      end
    end

    context 'when doorkeeper return URL only matches by prefix' do
      let(:doorkeeper_return_to) { '/oauth/authorize-anything' }

      it 'returns nil' do
        expect(described_class.run(user:, session:, options:)).to be_nil
      end
    end
  end
end
