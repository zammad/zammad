# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend_examples'
require 'auth/ldap'

RSpec.describe ::Auth::Ldap do

  let(:user) { create(:user) }
  let(:password) { 'somepassword' }
  let(:instance) { described_class.new({ adapter: described_class.name }) }

  describe '#valid?' do
    it_behaves_like 'Auth backend'

    it 'authenticates users' do

      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)

      ldap_user = double(valid?: true)
      allow(::Ldap::User).to receive(:new).and_return(ldap_user)

      result = instance.valid?(user, password)
      expect(result).to be true
    end

    it 'authenticates via configurable user attributes' do

      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)

      instance = described_class.new(
        adapter:          described_class.name,
        login_attributes: %w[firstname],
      )

      ldap_user = double
      allow(ldap_user).to receive(:valid?).with(user.firstname, password).and_return(true)

      allow(::Ldap::User).to receive(:new).and_return(ldap_user)

      result = instance.valid?(user, password)
      expect(result).to be true
    end

    context 'invalid' do

      it "doesn't authenticate if 'ldap_integration' Setting is disabled" do

        allow(Setting).to receive(:get)
        allow(Setting).to receive(:get).with('ldap_integration').and_return(false)

        result = instance.valid?(user, password)
        expect(result).to be false
      end

      it "doesn't authenticate if ldap says 'nope'" do

        allow(Setting).to receive(:get)
        allow(Setting).to receive(:get).with('ldap_integration').and_return(true)

        ldap_user = double(valid?: false)
        allow(::Ldap::User).to receive(:new).and_return(ldap_user)

        result = instance.valid?(user, password)
        expect(result).to be false
      end
    end
  end
end
