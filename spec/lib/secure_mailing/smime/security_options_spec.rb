# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SecureMailing::SMIME::SecurityOptions, :aggregate_failures do
  before do
    Setting.set('smime_integration', true)
  end

  let(:instance)            { described_class.new(ticket:, article:) }
  let(:certificate)         { create(:smime_certificate, :with_private, fixture: 'smime1@example.com') }
  let(:expired_certificate) { create(:smime_certificate, :with_private, fixture: 'expiredsmime1@example.com') }

  describe '.process' do
    let(:email_address) { create(:email_address, email: 'smime1@example.com') }
    let(:group)   { create(:group, email_address: email_address) }
    let(:ticket)  { { 'group_id' => group.id } }
    let(:article) { { 'to' => 'smime1@example.com', 'from' => 'smime1@example.com' } }

    context 'without certificates present on the system' do

      it 'has no possible security options' do
        expect(instance.process.signing).to have_attributes(possible?: false, active_by_default?: false, message: 'The certificate for %s was not found.', message_placeholders: ['smime1@example.com'])
        expect(instance.process.encryption).to have_attributes(possible?: false, active_by_default?: false, message: 'The certificate for smime1@example.com was not found.', message_placeholders: [])
      end

    end

    context 'without sender email address' do
      let(:group) { create(:group, email_address: nil) }

      it 'has no possible security options' do
        expect(instance.process.signing).to have_attributes(possible?: false, active_by_default?: false, message: 'There was no certificate found.', message_placeholders: [])
        expect(instance.process.encryption).to have_attributes(possible?: false, active_by_default?: false, message: 'The certificate for smime1@example.com was not found.', message_placeholders: [])
      end

    end

    context 'with valid certificate for sender and receiver' do
      before do
        certificate
      end

      it 'allows signing and encryption' do
        expect(instance.process.signing).to have_attributes(possible?: true, active_by_default?: true, message: 'The certificate for %s was found.', message_placeholders: ['smime1@example.com'])
        expect(instance.process.encryption).to have_attributes(possible?: true, active_by_default?: true, message: 'The certificates for %s were found.', message_placeholders: ['smime1@example.com'])
      end
    end

    context 'with expired certificate for sender and receiver' do
      before do
        expired_certificate
      end

      let(:email_address) { create(:email_address, email: 'expiredsmime1@example.com') }
      let(:article)       { { 'to' => 'expiredsmime1@example.com', 'from' => 'expiredsmime1@example.com' } }

      it 'allows signing and encryption' do
        expect(instance.process.signing).to have_attributes(possible?: false, active_by_default?: false, message: 'The certificate for %s was found, but it is not valid yet or has expired.', message_placeholders: ['expiredsmime1@example.com'])
        expect(instance.process.encryption).to have_attributes(possible?: false, active_by_default?: false, message: 'There were certificates found for %s, but at least one of them is not valid yet or has expired.', message_placeholders: ['expiredsmime1@example.com'])
      end
    end

  end
end
