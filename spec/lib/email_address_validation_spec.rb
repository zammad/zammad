# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailAddressValidation do
  shared_examples 'email address validity' do |valid:, check_mx:|
    let(:email_address_validation) { described_class.new(email_address) }

    it 'reports given email address' do
      expect(email_address_validation.email_address).to eq(email_address)
      expect(email_address_validation.to_s).to eq(email_address)
    end

    it "reports email address as #{valid ? 'valid' : 'invalid'}" do
      expect(email_address_validation.valid?(check_mx: check_mx)).to be(valid)
    end
  end

  describe 'Email address' do
    describe 'with MX record' do
      let(:email_address) { 'greetings@zammad.org' }

      include_examples 'email address validity', valid: true, check_mx: true
    end

    describe 'without MX record' do
      let(:email_address) { 'someone@this-is-probably-a-non-existent-domain.com.example' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'with unicode characters' do
      let(:email_address) { 'ąžuolas@paštas.com' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'with special characters' do
      let(:email_address) { '"a+ddress="@example.com' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'with short legacy gmail address' do
      let(:email_address) { 'you@gmail.com' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'when very long local part' do
      let(:email_address) { 'd+aorgprcb5rboeldeti12rh-4fs92usdgsdzkw1xfppexrzd_efcxum1rxchmhjlplidc99k0141zduz2rmsvi2boiep-8b3-xh1dtbdvqjqn7lhguq6zh4nza8jmc2pv3thujtjatgtk@docs.google.com' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'when max length' do
      let(:email_address) { 'trulyverylongpastasdomainnamehere.trulyverylongpastasdomain@trulyverylongpastasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpastasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpastasdomainnameheredoublethatloremipsumname.com' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'when over max length' do
      let(:email_address) { 'trulyverylongpastasdomainnamehere.trulyverylongpastasdomainnamee@trulyverylongpastasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpastasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpastasdomainnameheredoublethatloremipsumname.com' }

      include_examples 'email address validity', valid: false, check_mx: false
    end

    describe 'when max length with unicode characters' do
      let(:email_address) { 'trulyverylongpaštasdomainnamehere.trulyverylongpaštasdomain@trulyverylongpaštasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpaštasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpaštasdomainnameheredob.com' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'when local non-localhost email' do
      let(:email_address) { 'test@localhost' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'without dot in domain' do
      let(:email_address) { 'greetings@localhost' }

      include_examples 'email address validity', valid: true, check_mx: false
    end

    describe 'without domain' do
      let(:email_address) { 'zammad' }

      include_examples 'email address validity', valid: false, check_mx: false
    end

    describe 'when too long' do
      let(:email_address) { 'trulyverylongpastasdomainnamehere.trulyverylongpastasdomainnamee@trulyverylongpastasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpastasdomainnameheredoublethatloremipsumnamecodena.trulyverylongpastasdomainnameheredoublethatloremipsumnametoolong.com' }

      include_examples 'email address validity', valid: false, check_mx: false
    end

    describe 'with invalid domain format' do
      let(:email_address) { 'greetings@example..com' }

      include_examples 'email address validity', valid: false, check_mx: false
    end

    describe 'which is empty' do
      let(:email_address) { '' }

      include_examples 'email address validity', valid: false, check_mx: false
    end
  end
end
