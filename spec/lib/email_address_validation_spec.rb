# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailAddressValidation do

  describe 'Valid email address' do

    describe 'with dot in domain' do

      describe 'with MX record' do
        let(:email_address) { 'greetings@example.com' }
        let(:email_address_validation) { described_class.new(email_address) }

        it 'reports given email address' do
          expect(email_address_validation.email_address).to eq(email_address)
          expect(email_address_validation.to_s).to eq(email_address)
        end

        it 'reports email address as valid' do
          expect(email_address_validation.valid_format?).to be(true)
        end

        it 'reports email address to have domain with MX record' do
          expect(email_address_validation.valid_mx?).to be(true)
        end
      end

      describe 'without MX record' do
        let(:email_address) { 'someone@this-is-probably-a-non-existent-domain.com.example' }
        let(:email_address_validation) { described_class.new(email_address) }

        it 'reports given email address' do
          expect(email_address_validation.email_address).to eq(email_address)
          expect(email_address_validation.to_s).to eq(email_address)
        end

        it 'reports email address as valid' do
          expect(email_address_validation.valid_format?).to be(true)
        end

        it 'reports email address to have domain without MX record' do
          expect(email_address_validation.valid_mx?).to be(false)
        end
      end

    end

    describe 'without dot in domain' do
      let(:email_address) { 'greetings@localhost' }
      let(:email_address_validation) { described_class.new(email_address) }

      it 'reports given email address' do
        expect(email_address_validation.email_address).to eq(email_address)
        expect(email_address_validation.to_s).to eq(email_address)
      end

      it 'reports email address as valid' do
        expect(email_address_validation.valid_format?).to be(true)
      end

      it 'reports email address to have domain without MX record' do
        expect(email_address_validation.valid_mx?).to be(false)
      end
    end

  end

  describe 'Email address' do

    describe 'without domain' do
      let(:email_address) { 'zammad' }
      let(:email_address_validation) { described_class.new(email_address) }

      it 'reports given email address' do
        expect(email_address_validation.email_address).to eq(email_address)
        expect(email_address_validation.to_s).to eq(email_address)
      end

      it 'reports email address as invalid' do
        expect(email_address_validation.valid_format?).to be(false)
      end

      it 'reports email address to have domain without MX record' do
        expect(email_address_validation.valid_mx?).to be(false)
      end
    end

    describe 'with invalid domain format' do
      let(:email_address) { 'greetings@example..com' }
      let(:email_address_validation) { described_class.new(email_address) }

      it 'reports given email address' do
        expect(email_address_validation.email_address).to eq(email_address)
        expect(email_address_validation.to_s).to eq(email_address)
      end

      it 'reports email address as invalid' do
        expect(email_address_validation.valid_format?).to be(false)
      end

      it 'reports email address to have domain without MX record' do
        expect(email_address_validation.valid_mx?).to be(false)
      end
    end

    describe 'which is empty' do
      let(:email_address) { '' }
      let(:email_address_validation) { described_class.new(email_address) }

      it 'reports given email address' do
        expect(email_address_validation.email_address).to eq(email_address)
        expect(email_address_validation.to_s).to eq(email_address)
      end

      it 'reports email address as invalid' do
        expect(email_address_validation.valid_format?).to be(false)
      end

      it 'reports email address to have domain without MX record' do
        expect(email_address_validation.valid_mx?).to be(false)
      end
    end

  end

end
