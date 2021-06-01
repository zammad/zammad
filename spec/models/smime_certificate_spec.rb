# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SMIMECertificate, type: :model do

  describe '.for_sender_email_address' do

    let(:lookup_address) { 'smime1@example.com' }

    context 'no certificate present' do
      it 'returns nil' do
        expect(described_class.for_sender_email_address(lookup_address)).to be nil
      end
    end

    context 'certificate present' do

      context 'with private key' do

        let!(:certificate) { create(:smime_certificate, :with_private, fixture: lookup_address) }

        it 'returns certificate' do
          expect(described_class.for_sender_email_address(lookup_address)).to eq(certificate)
        end
      end

      context 'without private key' do

        before do
          create(:smime_certificate, fixture: lookup_address)
        end

        it 'returns nil' do
          expect(described_class.for_sender_email_address(lookup_address)).to be nil
        end
      end

      context 'different letter case' do

        let(:fixture) { 'CaseInsenstive@eXample.COM' }
        let(:lookup_address) { 'CaseInsenStive@Example.coM' }

        context 'with private key' do

          let!(:certificate) { create(:smime_certificate, :with_private, fixture: fixture) }

          it 'returns certificate' do
            expect(described_class.for_sender_email_address(lookup_address)).to eq(certificate)
          end
        end
      end
    end
  end

  describe 'for_recipipent_email_addresses!' do

    context 'no certificate present' do

      let(:lookup_addresses) { ['smime1@example.com', 'smime2@example.com'] }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.for_recipipent_email_addresses!(lookup_addresses) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'not all certificates present' do

      let(:existing_address) { 'smime1@example.com' }
      let(:not_existing_address) { 'smime2@example.com' }
      let(:lookup_addresses) { [existing_address, not_existing_address] }

      before do
        create(:smime_certificate, fixture: existing_address)
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.for_recipipent_email_addresses!(lookup_addresses) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'exception message' do

        let(:message) do
          described_class.for_recipipent_email_addresses!(lookup_addresses)
        rescue => e
          e.message
        end

        it 'does not contain found address' do
          expect(message).not_to include(existing_address)
        end

        it 'contains address not found' do
          expect(message).to include(not_existing_address)
        end
      end
    end

    context 'all certificates present' do

      let(:lookup_addresses) { ['smime1@example.com', 'smime2@example.com'] }

      let!(:certificates) do
        lookup_addresses.map do |existing_address|
          create(:smime_certificate, fixture: existing_address)
        end
      end

      it 'returns certificates' do
        expect(described_class.for_recipipent_email_addresses!(lookup_addresses)).to eq(certificates)
      end
    end

    context 'different letter case' do

      let(:fixture) { 'CaseInsenstive@eXample.COM' }
      let(:lookup_addresses) { ['CaseInsenStive@Example.coM'] }

      let!(:certificates) do
        [ create(:smime_certificate, fixture: fixture) ]
      end

      it 'returns certificates' do
        expect(described_class.for_recipipent_email_addresses!(lookup_addresses)).to eq(certificates)
      end
    end

  end

  describe '#email_addresses' do

    context 'certificate with single email address' do
      let(:email_address) { 'smime1@example.com' }
      let(:certificate) { create(:smime_certificate, fixture: email_address) }

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
        expect(certificate.expired?).to be true
      end
    end

    context 'valid' do
      let(:fixture) { 'smime1@example.com' }

      it 'returns false' do
        expect(certificate.expired?).to be false
      end
    end
  end

  context 'certificate parsing' do

    context 'expiration dates' do

      shared_examples 'correctly parsed' do |fixture|
        let(:certificate) { create(:smime_certificate, fixture: fixture) }

        it "handles '#{fixture}' fixture" do
          expect(certificate.not_before_at).to a_kind_of(ActiveSupport::TimeWithZone)
          expect(certificate.not_after_at).to a_kind_of(ActiveSupport::TimeWithZone)
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
