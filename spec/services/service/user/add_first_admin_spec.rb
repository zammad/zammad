# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::AddFirstAdmin do
  subject(:service_result) { described_class.execute(user_data:, request:) }

  let(:accept_language) { 'de-de' }
  let(:request)         { instance_double(ActionDispatch::Request, remote_ip: '203.0.113.1', env: { 'HTTP_ACCEPT_LANGUAGE' => accept_language }) }
  let(:password)        { 'IloveBender1337' }
  let(:email)           { 'bender@futurama.fiction' }
  let(:user_data) do
    {
      email:     email,
      firstname: 'Bender',
      lastname:  'Rodríguez',
      password:  password,
    }
  end

  before do
    Setting.set('system_init_done', false)

    allow(Calendar).to receive(:init_setup)
    allow(TextModule).to receive(:load)
    allow(Service::Image).to receive(:organization_suggest)
  end

  shared_examples 'not creating a user' do |error_class, message|
    it 'raises an error and does not create a user', :aggregate_failures do
      expect { service_result }
        .to raise_error(error_class, include(message))
        .and not_change(User, :count)

      expect(Setting.get('system_init_done')).to be(false)
    end
  end

  describe '#execute' do
    it 'creates the user as admin and agent with access to all groups', :aggregate_failures do
      expect(service_result).to be_persisted.and have_attributes(email:, firstname: 'Bender', lastname: 'Rodríguez')
      expect(service_result.roles).to match_array(Role.where(name: %w[Admin Agent]))
      expect(service_result.group_ids).to match_array(Group.pluck(:id))
    end

    it 'marks the system setup as done' do
      expect { service_result }.to change { Setting.get('system_init_done') }.from(false).to(true)
    end

    it 'configures the system based on the request', :aggregate_failures do
      service_result

      expect(Service::Image).to have_received(:organization_suggest).with(email)
      expect(Calendar).to have_received(:init_setup).with('203.0.113.1')
      expect(TextModule).to have_received(:load).with('de-de')
    end

    context 'without an accept language header' do
      let(:accept_language) { nil }

      it 'loads the default text modules' do
        service_result

        expect(TextModule).to have_received(:load).with('en-us')
      end
    end

    context 'when the text modules cannot be loaded' do
      before do
        allow(TextModule).to receive(:load).and_raise('no text modules')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and creates the user anyway', :aggregate_failures do
        expect(service_result).to be_persisted
        expect(Rails.logger).to have_received(:error).with('Unable to load text modules de-de: no text modules')
      end
    end

    context 'when the system has already been configured' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      it 'raises an error and does not create a user' do
        expect { service_result }
          .to raise_error(Service::System::CheckSetup::SystemSetupError, 'This system has already been configured and an administrator account exists.')
          .and not_change(User, :count)
      end
    end

    context 'without an email address' do
      let(:email) { '' }

      it_behaves_like 'not creating a user', Exceptions::MissingAttribute, "The required attribute 'email' is missing."
    end

    context 'with a weak password' do
      let(:password) { '1234' }

      it_behaves_like 'not creating a user', PasswordPolicy::Error, 'Invalid password'
    end
  end
end
