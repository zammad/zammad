# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend/backend_examples'

RSpec.describe Auth::Backend::Ldap do

  let(:ldap_source) { create(:ldap_source) }
  let(:user)        { create(:user, source: "Ldap::#{ldap_source.id}") }
  let(:password)    { 'secure' }
  let(:auth)        { Auth.new(user.login, password) }
  let(:config) do
    {
      adapter: described_class.name
    }
  end
  let(:instance) { described_class.new(config, auth) }
  let(:ldap_integration) { true }

  before do
    Setting.set('ldap_integration', ldap_integration)
  end

  describe '#valid?' do
    let(:ldap_user) { instance_double(Ldap::User) }

    before do
      allow(Ldap::User).to receive(:new).with(any_args).and_return(ldap_user)
      allow(ldap_user).to receive(:valid?).with(any_args).and_return(true)
    end

    it_behaves_like 'Auth backend'

    it 'authenticates users' do
      expect(instance.valid?).to be true
    end

    context 'when custom login attribute is configured' do

      let(:config) do
        super().merge(
          login_attributes: %w[firstname]
        )
      end

      it 'authenticates' do
        allow(ldap_user).to receive(:valid?).with(user.firstname, password).and_return(true)

        expect(instance.valid?).to be true
      end
    end

    context 'when Setting ldap_integration is false' do

      let(:ldap_integration) { false }

      it "doesn't authenticate" do
        expect(instance.valid?).to be false
      end
    end

    context 'when LDAP authentication fails' do

      it "doesn't authenticate" do
        allow(ldap_user).to receive(:valid?).with(any_args).and_return(false)

        expect(instance.valid?).to be false
      end
    end

    context 'when User#source does not match Ldap' do

      context 'when blank' do

        let(:user) { create(:user) }

        it "doesn't authenticate" do
          expect(instance.valid?).to be false
        end
      end

      context 'when some other value' do

        let(:user) { create(:user, source: 'some other value') }

        it "doesn't authenticate" do
          expect(instance.valid?).to be false
        end
      end
    end
  end
end
