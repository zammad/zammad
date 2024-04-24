# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::ChangePassword do
  let(:user)    { create(:user, password: 'password') }
  let(:service) { described_class.new(user: user, current_password: current_password, new_password: new_password) }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
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
      let(:new_password)     { 'FooBarbazbaz' }

      it_behaves_like 'raising an error', PasswordPolicy::Error, 'Invalid password, it must contain at least 1 digit!'
    end

    context 'with valid passwords' do
      let(:current_password) { 'password' }
      let(:new_password)     { 'IamAnValidPassword111einseinself' }

      it 'returns true' do
        expect(service.execute).to be_truthy
      end

      it 'changes the password' do
        expect { service.execute }.to change { user.reload.password }
      end

      it 'notifies the user' do
        allow(NotificationFactory::Mailer).to receive(:notification).with(
          template: 'password_change',
          user:     user,
          objects:  {
            user: user,
          }
        )
        service.execute

        expect(NotificationFactory::Mailer).to have_received(:notification)
      end
    end
  end
end
