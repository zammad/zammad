# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordReset::Send do
  subject(:service) { described_class.new(username: user.login) }

  let(:user) { create(:user) }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
    end
  end

  shared_examples 'sending the token' do
    it 'returns success' do
      expect(service.execute).to be(true)
    end

    it 'generates a new token' do
      expect { service.execute }.to change(Token, :count)
    end

    it 'sends a valid password reset link' do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      service.execute

      expect(message).to include "<a href=\"http://zammad.example.com/desktop/reset-password/verify/#{Token.last.token}\">"
    end
  end

  shared_examples 'returning success' do
    it 'returns success' do
      expect(service.execute).to be(true)
    end

    it 'does not generate a new token' do
      expect { service.execute }.to not_change(Token, :count)
    end
  end

  describe '#execute' do
    context 'with disabled lost password feature' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
    end

    context 'with a valid user login' do
      it_behaves_like 'sending the token'
    end

    context 'with a valid user email' do
      subject(:service) { described_class.new(username: user.email) }

      it_behaves_like 'sending the token'
    end

    context 'with an invalid user login' do
      subject(:service) { described_class.new(username: 'foobar') }

      it_behaves_like 'returning success'
    end
  end
end
