# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::AddFirstAdmin, set_up: false do
  subject(:service_result) { described_class.execute(user_data:, request:) }

  let(:request)   { instance_double(ActionDispatch::Request, remote_ip: '127.0.0.1', env: {}) }
  let(:email)     { 'bender@futurama.fiction' }
  let(:user_data) { { email:, firstname: 'Bender', lastname: 'Rodríguez', password: 'IloveBender1337' } }

  before do
    allow(Calendar).to receive(:init_setup)
    allow(TextModule).to receive(:load)
  end

  context 'with a new system' do
    it 'creates an admin with access to all groups', :aggregate_failures do
      expect(service_result).to have_attributes(
        email:     email,
        roles:     match_array(Role.where(name: %w[Admin Agent])),
        group_ids: match_array(Group.pluck(:id)),
      )
      expect(Setting.get('system_init_done')).to be(true)
    end
  end

  context 'with a completed setup' do
    before do
      create(:admin)
      Setting.set('system_init_done', true)
    end

    it 'raises an error and creates no user', :aggregate_failures do
      expect { service_result }.to raise_error(Service::System::CheckSetup::SystemSetupError, 'This system has already been configured and an administrator account exists.')
      expect(User.find_by(email:)).to be_nil
    end
  end

  context 'with a running import' do
    before do
      Setting.set('import_mode', true)
    end

    shared_examples 'refusing the first admin' do
      it 'raises an error and creates no user', :aggregate_failures do
        expect { service_result }.to raise_error(Service::System::CheckSetup::SystemSetupError, 'The system setup cannot be started, because there is another one running or it was completed before.')
        expect(User.find_by(email:)).to be_nil
      end
    end

    context 'when no admin has been imported yet' do
      it_behaves_like 'refusing the first admin'
    end

    context 'when admins have been imported' do
      before { create(:admin) }

      it_behaves_like 'refusing the first admin'
    end

    context 'when the setup is marked as done' do
      before do
        create(:admin)
        Setting.set('system_init_done', true)
      end

      it_behaves_like 'refusing the first admin'
    end
  end

  context 'without an email address' do
    let(:email) { '' }

    it 'raises an error' do
      expect { service_result }.to raise_error(Exceptions::MissingAttribute)
    end
  end
end
