# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Signup do
  subject(:service) { described_class.new(user_data: user_data, resend: resend) }

  let(:resend) { false }

  let(:user_data) do
    {
      email:     'bender@futurama.fiction',
      firstname: 'Bender',
      lastname:  'Rodríguez',
      password:  'IloveBender1337'
    }
  end

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, include(message))
    end
  end

  shared_examples 'returning success' do |with_new_user: false, with_existing_user: false, with_resend: false|
    it 'returns success' do
      expect(service.execute).to be(true)
    end

    it 'creates an unverified user account', if: with_new_user do
      service.execute
      expect(User.find_by(email: 'bender@futurama.fiction')).to be_present.and have_attributes(verified: false)
    end

    it 'sends an email with the verification link', if: with_new_user || (!with_existing_user && with_resend) do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      service.execute

      expect(message).to include("<a href=\"http://zammad.example.com/desktop/signup/verify/#{Token.last[:token]}\">")
    end

    it 'sends an email with the password reset link', if: with_existing_user && !with_resend do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      service.execute

      expect(message).to include("<a href=\"http://zammad.example.com/desktop/reset-password/verify/#{Token.last[:token]}\">")
    end

    it 'sends no email', if: !with_new_user && with_existing_user && with_resend do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      service.execute

      expect(message).to be_nil
    end
  end

  describe '#execute' do
    context 'with disabled user signup' do
      before do
        Setting.set('user_create_account', false)
      end

      it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
    end

    context 'with valid user data' do
      it_behaves_like 'returning success', with_new_user: true
    end

    context 'with invalid user data' do
      let(:password) { 'IloveBender1337' }
      let(:user_data) do
        {
          email:     'bender@futurama.fiction',
          firstname: 'Bender',
          lastname:  'Rodríguez',
          password:  password
        }
      end

      context 'when the password is weak' do
        let(:password) { 'idonotlovebenderandthisiswrong' }

        it_behaves_like 'raising an error', PasswordPolicy::Error, 'Invalid password'
      end

      context 'when the email is already taken' do
        before do
          create(:user, email: 'bender@futurama.fiction')
        end

        it_behaves_like 'returning success', with_existing_user: true
      end
    end

    context 'when resending verification email' do
      let(:resend)   { true }
      let(:verified) { false }

      before do
        create(:user, email: 'bender@futurama.fiction', verified: verified)
      end

      it_behaves_like 'returning success', with_resend: true

      context 'when user is already verified' do
        let(:verified) { true }

        it_behaves_like 'returning success', with_existing_user: true, with_resend: true
      end
    end
  end
end
