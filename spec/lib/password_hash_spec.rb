# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PasswordHash do

  let(:pw_plain) { 'zammad' }

  context 'stable API' do
    it 'responds to crypt' do
      expect(described_class).to respond_to(:crypt)
    end

    it 'responds to verified?' do
      expect(described_class).to respond_to(:verified?)
    end

    it 'responds to crypted?' do
      expect(described_class).to respond_to(:crypted?)
    end

    it 'responds to legacy?' do
      expect(described_class).to respond_to(:legacy?)
    end

    it 'responds to sha2' do
      expect(described_class).to respond_to(:sha2)
    end

    it 'responds to hashed_sha2?' do
      expect(described_class).to respond_to(:hashed_sha2?)
    end

    it 'responds to hashed_argon2?' do
      expect(described_class).to respond_to(:hashed_argon2?)
    end
  end

  context 'encryption' do

    it 'crypts passwords' do
      pw_crypted = described_class.crypt(pw_plain)
      expect(pw_crypted).not_to eq(pw_plain)
    end

    it 'verifies crypted passwords' do
      pw_crypted = described_class.crypt(pw_plain)
      expect(described_class.verified?(pw_crypted, pw_plain)).to be true
    end

    it 'detects crypted passwords' do
      pw_crypted = described_class.crypt(pw_plain)
      expect(described_class.crypted?(pw_crypted)).to be true
    end
  end

  context 'legacy' do

    let(:zammad_sha2) { '{sha2}dd9c764fa7ea18cd992c8600006d3dc3ac983d1ba22e9ba2d71f6207456be0ba' }

    it 'requires hash to be not blank' do
      expect(described_class).not_to be_legacy(nil, pw_plain)
      expect(described_class).not_to be_legacy('', pw_plain)
    end

    it 'requires password to be not nil' do
      expect(described_class).not_to be_legacy(zammad_sha2, nil)
    end

    it 'detects sha2 hashes' do
      expect(described_class.legacy?(zammad_sha2, pw_plain)).to be true
    end

    it 'detects crypted passwords' do
      expect(described_class.crypted?(zammad_sha2)).to be true
    end

    describe '::sha2' do

      it 'creates sha2 hashes' do
        hashed = described_class.sha2(pw_plain)
        expect(hashed).to eq zammad_sha2
      end
    end

    describe '::hashed_sha2?' do

      it 'detects sha2 hashes' do
        expect(described_class.hashed_sha2?(zammad_sha2)).to be true
      end
    end
  end

end
