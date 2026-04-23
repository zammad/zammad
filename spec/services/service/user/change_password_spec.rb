# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::ChangePassword do
  subject(:service_result) { described_class.with_current_user(user).execute(current_password:, new_password:) }

  let(:user) { create(:user, password: 'password') }

  shared_examples 'raising an error' do |klass, message, message_placeholder: nil|
    if message_placeholder
      it 'raises an error', aggregate_failures: true do
        expect { service_result }.to raise_error do |error|
          expect(error).to be_a(klass)
            .and have_attributes(
              message:  include(message),
              metadata: [include(message), *message_placeholder],
            )
        end
      end
    else
      it 'raises an error' do
        expect { service_result }.to raise_error(klass, include(message))
      end
    end
  end

  describe '#execute' do
    context 'with not matching current password' do
      let(:current_password) { 'foobar' }
      let(:new_password)     { 'new_password' }

      it_behaves_like 'raising an error', PasswordHash::Error, 'The password is invalid.'
    end

    context 'with password policy violation' do
      let(:current_password) { 'password' }
      let(:new_password)     { 'fooBAR42' }

      it_behaves_like 'raising an error', PasswordPolicy::Error, 'Invalid password, it must be at least %s characters long!', message_placeholder: [10]
    end

    context 'with valid passwords' do
      let(:current_password) { 'password' }
      let(:new_password)     { 'IamAnValidPassword111einseinself' }

      it 'returns true' do
        expect(service_result).to be_truthy
      end

      it 'changes the password' do
        expect { service_result }.to change { user.reload.password }
      end

      it 'notifies the user' do
        allow(NotificationFactory::Mailer).to receive(:notification).with(
          template: 'password_change',
          user:     user,
          objects:  {
            user: user,
          }
        )
        service_result

        expect(NotificationFactory::Mailer).to have_received(:notification)
      end
    end
  end
end
