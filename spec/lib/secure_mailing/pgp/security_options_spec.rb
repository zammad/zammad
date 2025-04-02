# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SecureMailing::PGP::SecurityOptions, :aggregate_failures do
  before do
    Setting.set('pgp_integration', true)
  end

  let(:instance)    { described_class.new(ticket:, article:) }
  let(:pgp_key)     { create(:pgp_key, :with_private, fixture: 'zammad@localhost') }
  let(:expired_key) { create(:pgp_key, :with_private, fixture: 'expiredpgp1@example.com') }

  describe '.process' do
    let(:email_address) { create(:email_address, email: 'zammad@localhost') }
    let(:group)   { create(:group, email_address: email_address) }
    let(:ticket)  { { 'group_id' => group.id } }
    let(:article) { { 'to' => 'zammad@localhost', 'from' => 'zammad@localhost' } }

    context 'without keys present on the system' do

      it 'has no possible security options' do
        expect(instance.process.signing).to have_attributes(possible?: false, active_by_default?: false, message: 'The PGP key for %s was not found.', message_placeholders: ['zammad@localhost'])
        expect(instance.process.encryption).to have_attributes(possible?: false, active_by_default?: false, message: 'The PGP key for %s was not found.', message_placeholders: ['zammad@localhost'])
      end

    end

    context 'without sender email address' do
      let(:group) { create(:group, email_address: nil) }

      it 'has no possible security options' do
        expect(instance.process.signing).to have_attributes(possible?: false, active_by_default?: false, message: 'There was no PGP key found.', message_placeholders: [])
        expect(instance.process.encryption).to have_attributes(possible?: false, active_by_default?: false, message: 'The PGP key for %s was not found.', message_placeholders: ['zammad@localhost'])
      end

    end

    context 'with valid key for sender and receiver' do
      before { pgp_key }

      it 'allows signing and encryption' do
        expect(instance.process.signing).to have_attributes(possible?: true, active_by_default?: true, message: 'The PGP key for %s was found.', message_placeholders: ['zammad@localhost'])
        expect(instance.process.encryption).to have_attributes(possible?: true, active_by_default?: true, message: 'The PGP keys for %s were found.', message_placeholders: ['zammad@localhost'])
      end
    end

    context 'with expired key for sender and receiver' do
      before do
        expired_key
      end

      let(:email_address) { create(:email_address, email: 'expiredpgp1@example.com') }
      let(:article)       { { 'to' => 'expiredpgp1@example.com', 'from' => 'expiredpgp1@example.com' } }

      it 'allows signing and encryption' do
        expect(instance.process.signing).to have_attributes(possible?: false, active_by_default?: false, message: 'The PGP key for %s was found, but has expired.', message_placeholders: ['expiredpgp1@example.com'])
        expect(instance.process.encryption).to have_attributes(possible?: false, active_by_default?: false, message: 'There were PGP keys found for %s, but at least one of them has expired.', message_placeholders: ['expiredpgp1@example.com'])
      end
    end

    context 'with used domain alias keys' do
      before do
        Setting.set('pgp_recipient_alias_configuration', true)
      end

      context 'with valid key for sender and receiver' do
        let(:pgp_key)     { create(:pgp_key, :with_private, fixture: 'zammad@localhost', domain_alias: 'domain3.com') }
        let(:email_address) { create(:email_address, email: 'support@domain3.com') }
        let(:group)         { create(:group, email_address: email_address) }
        let(:ticket)        { { 'group_id' => group.id } }
        let(:article)       { { 'to' => 'support@domain3.com', 'from' => 'support@domain3.com' } }

        before { pgp_key }

        it 'allows signing and encryption' do
          expect(instance.process.signing).to have_attributes(possible?: true, active_by_default?: true, message: 'The PGP key for %s was found.', message_placeholders: ['support@domain3.com'])
          expect(instance.process.encryption).to have_attributes(possible?: true, active_by_default?: true, message: 'The PGP keys for %s were found.', message_placeholders: ['support@domain3.com'])
        end
      end
    end
  end
end
