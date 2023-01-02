# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::User::Skip::IsLdapSource, sequencer: :unit do
  let(:ldap_source) { create(:ldap_source) }
  let(:user)        { create(:user, source: "Ldap::#{ldap_source.id}") }

  context 'when LDAP integration is disabled' do
    before do
      Setting.set('ldap_integration', false)
    end

    it 'does not skip' do
      result = process({
                         instance: user,
                       })

      expect(result).not_to include(action: :skipped)
    end
  end

  context 'when LDAP integration is enabled' do
    before do
      Setting.set('ldap_integration', true)
    end

    context 'when LDAP source is active' do
      it 'does skip' do
        result = process({
                           instance: user,
                         })

        expect(result).to include(action: :skipped)
      end
    end

    context 'when LDAP source is not active' do
      let(:ldap_source) { create(:ldap_source, active: false) }

      it 'does not skip' do
        result = process({
                           instance: user,
                         })

        expect(result).not_to include(action: :skipped)
      end
    end
  end
end
