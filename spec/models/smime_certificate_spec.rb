# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SMIMECertificate, type: :model do

  describe '.find_for_multiple_email_addresses' do
    let(:filter) { { key: key_filter, usage: usage_filter, ignore_usable: ignore_usable_filter } }

    context 'send encrypted mail to recipient' do
      let(:ignore_usable_filter) { false }
      let(:key_filter)           { 'public' }
      let(:usage_filter)         { :encryption }

      context 'when recipient certificate is missing' do
        it 'returns no certificate' do
          expect { described_class.find_for_multiple_email_addresses!(['smime1@example.com'], filter: filter, blame: true) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when recipient certificate is available and usable for encryption' do
        let!(:certificate) { create(:smime_certificate, fixture: 'alice@acme.corp+sign+encrypt') }

        it 'returns the certificate' do
          expect(described_class.find_for_multiple_email_addresses!(['alice@acme.corp'], filter: filter, blame: true)).to eq([certificate])
        end
      end

      context 'when recipient certificate is available, but not usable for encryption' do
        before do
          create(:smime_certificate, fixture: 'alice@acme.corp+sign')
        end

        it 'returns no certificate' do
          expect { described_class.find_for_multiple_email_addresses!(['alice@acme.corp'], filter: filter, blame: true) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when multiple recipient certificates are available' do
        let!(:certificate) do
          create(:smime_certificate, fixture: 'alice@acme.corp+sign')
          create(:smime_certificate, fixture: 'alice@acme.corp+encrypt')
        end

        it 'only returns certificates usable for encryption' do
          expect(described_class.find_for_multiple_email_addresses!(['alice@acme.corp'], filter: filter, blame: true)).to eq([certificate])
        end
      end
    end

    context 'receive signed e-mail' do
      let(:ignore_usable_filter) { false }
      let(:key_filter)           { 'public' }
      let(:usage_filter)         { :signature }

      context 'when sender certificate is not usable for signature verification' do # rubocop:disable RSpec/RepeatedExampleGroupBody
        before do
          create(:smime_certificate, fixture: 'alice@acme.corp+encrypt')
        end

        it 'returns no certificate' do
          expect { described_class.find_for_multiple_email_addresses!(['alice@acme.corp'], filter: filter, blame: true) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when sender certificate is usable for signature verification' do
        let!(:certificate) { create(:smime_certificate, fixture: 'alice@acme.corp+sign+encrypt') }

        it 'returns the certificate' do
          expect(described_class.find_for_multiple_email_addresses!(['alice@acme.corp'], filter: filter, blame: true)).to eq([certificate])
        end
      end

      context 'when sender certificate is only usable for encryption' do # rubocop:disable RSpec/RepeatedExampleGroupBody
        before do
          create(:smime_certificate, fixture: 'alice@acme.corp+encrypt')
        end

        it 'returns no certificate' do
          expect { described_class.find_for_multiple_email_addresses!(['alice@acme.corp'], filter: filter, blame: true) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when sender certificate is missing' do
        it 'returns no certificate' do
          expect { described_class.find_for_multiple_email_addresses!(['smime1@example.com'], filter: filter, blame: true) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'send signed e-mail' do
      let(:ignore_usable_filter) { false }
      let(:key_filter)           { 'private' }
      let(:usage_filter)         { :signature }

      context 'when no sender private key is available' do
        before { create(:smime_certificate, fixture: 'alice@acme.corp+sign') }

        it 'returns no certificate' do
          expect(described_class.find_by_email_address('alice@acme.corp', filter: filter)).to eq([])
        end
      end

      context 'when the sender certificate has expired' do
        before do
          create(:smime_certificate, :with_private, fixture: 'alice@acme.corp+sign+encrypt+expired')
        end

        it 'returns no certificate' do
          expect(described_class.find_by_email_address('alice@acme.corp', filter: filter)).to eq([])
        end
      end

      context 'when a sender certificate with a private key is present' do
        let!(:certificate) { create(:smime_certificate, :with_private, fixture: 'alice@acme.corp+sign') }

        it 'returns the certificate' do
          expect(described_class.find_by_email_address('alice@acme.corp', filter: filter)).to eq([certificate])
        end
      end

      context 'when an expired sender certificate and an usable sender certificate is available' do
        let!(:usable_certificate) { create(:smime_certificate, :with_private, fixture: 'alice@acme.corp+sign+encrypt') }

        before do
          create(:smime_certificate, :with_private, fixture: 'alice@acme.corp+sign+encrypt+expired')
        end

        it 'returns the usable certificate' do
          expect(described_class.find_by_email_address('alice@acme.corp', filter: filter)).to eq([usable_certificate])
        end
      end
    end
  end

  describe '#email_addresses' do

    context 'certificate with single email address' do
      let(:email_address) { 'smime1@example.com' }
      let(:certificate)   { create(:smime_certificate, fixture: email_address) }

      it 'returns the mail address' do
        expect(certificate.email_addresses).to eq([email_address])
      end
    end

    context 'certificate with multiple email addresses' do
      let(:email_addresses) { ['smimedouble@example.com', 'smimedouble@example.de'] }
      let(:certificate) { create(:smime_certificate, fixture: 'smimedouble@example.com') }

      it 'returns all mail addresses' do
        expect(certificate.email_addresses).to eq(email_addresses)
      end
    end

  end

  describe '#expired?' do

    let(:certificate) { create(:smime_certificate, fixture: fixture) }

    context 'expired' do
      let(:fixture) { 'expiredsmime1@example.com' }

      it 'returns true' do
        expect(certificate.parsed.expired?).to be true
      end
    end

    context 'valid' do
      let(:fixture) { 'smime1@example.com' }

      it 'returns false' do
        expect(certificate.parsed.expired?).to be false
      end
    end
  end

  context 'certificate parsing' do

    context 'expiration dates' do

      shared_examples 'correctly parsed' do |fixture|
        let(:certificate) { create(:smime_certificate, fixture: fixture) }

        it "handles '#{fixture}' fixture" do
          expect(certificate.parsed.not_before).to a_kind_of(Time)
          expect(certificate.parsed.not_after).to a_kind_of(Time)
        end
      end

      it_behaves_like 'correctly parsed', 'smime1@example.com'
      it_behaves_like 'correctly parsed', 'smime2@example.com'
      it_behaves_like 'correctly parsed', 'smime3@example.com'
      it_behaves_like 'correctly parsed', 'CaseInsenstive@eXample.COM'

      it_behaves_like 'correctly parsed', 'RootCA'
      it_behaves_like 'correctly parsed', 'IntermediateCA'
      it_behaves_like 'correctly parsed', 'ChainCA'
    end
  end

  it 'ensures uniqueness of records' do
    expect { create_list(:smime_certificate, 2, fixture: 'smime1@example.com') }.to raise_error(ActiveRecord::RecordInvalid, %r{Validation failed})
  end
end
