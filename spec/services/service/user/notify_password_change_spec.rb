# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::NotifyPasswordChange do
  subject(:service_result) { described_class.with_current_user(current_user).execute(user: user) }

  let(:current_user) { create(:admin) }
  let(:user)         { create(:user) }

  before do
    allow(NotificationFactory::Mailer).to receive(:notification)
  end

  describe '#execute' do
    context 'when somebody else changed the password' do
      before { user.update!(password: generate(:password_valid)) }

      it 'notifies the user' do
        service_result

        expect(NotificationFactory::Mailer).to have_received(:notification).with(
          template: 'password_change',
          user:     user,
          objects:  {
            user: user,
          }
        ).once
      end
    end

    context 'when the email address changed in the same update' do
      let(:user) { create(:user, email: 'old-address@example.com') }

      before { user.update!(email: 'new-address@example.com', password: generate(:password_valid)) }

      it 'notifies the new address' do
        service_result

        expect(NotificationFactory::Mailer)
          .to have_received(:notification).with(hash_including(user: have_attributes(email: 'new-address@example.com')))
      end

      it 'notifies the previous address' do
        service_result

        expect(NotificationFactory::Mailer)
          .to have_received(:notification).with(hash_including(user: have_attributes(email: 'old-address@example.com')))
      end

      it 'renders the template for the updated user' do
        service_result

        expect(NotificationFactory::Mailer).to have_received(:notification).with(hash_including(objects: { user: user })).twice
      end
    end

    context 'when the user changed their own password' do
      let(:current_user) { user }

      before { user.update!(password: generate(:password_valid)) }

      it 'does not notify the user' do
        service_result

        expect(NotificationFactory::Mailer).not_to have_received(:notification)
      end
    end

    context 'when another attribute changed' do
      before { user.update!(lastname: 'Doe') }

      it 'does not notify the user' do
        service_result

        expect(NotificationFactory::Mailer).not_to have_received(:notification)
      end
    end

    context 'when the user has no email address' do
      let(:user) { create(:user, :without_email) }

      before { user.update!(password: generate(:password_valid)) }

      it 'does not notify the user' do
        service_result

        expect(NotificationFactory::Mailer).not_to have_received(:notification)
      end
    end

    context 'when the notification cannot be delivered' do
      before do
        allow(NotificationFactory::Mailer).to receive(:notification).and_raise(Channel::DeliveryError.new('SMTP server is unreachable', nil))

        user.update!(password: generate(:password_valid))
      end

      it 'does not fail the password change' do
        expect { service_result }.not_to raise_error
      end

      it 'logs the failure' do
        allow(Rails.logger).to receive(:error)

        service_result

        expect(Rails.logger).to have_received(:error).with(%r{SMTP server is unreachable})
      end
    end

    context 'when only the notification to the new address fails' do
      let(:user) { create(:user, email: 'old-address@example.com') }

      before do
        allow(NotificationFactory::Mailer).to receive(:notification)
          .with(hash_including(user: have_attributes(email: 'new-address@example.com')))
          .and_raise(Channel::DeliveryError.new('SMTP server is unreachable', nil))

        user.update!(email: 'new-address@example.com', password: generate(:password_valid))
      end

      it 'still notifies the previous address' do
        service_result

        expect(NotificationFactory::Mailer)
          .to have_received(:notification).with(hash_including(user: have_attributes(email: 'old-address@example.com')))
      end
    end

    context 'without a current user' do
      it 'raises an error' do
        expect { described_class.execute(user: user) }.to raise_error(%r{Current user is required})
      end
    end
  end
end
