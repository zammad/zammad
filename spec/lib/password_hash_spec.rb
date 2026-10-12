# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PasswordHash do

  let(:pw_plain) { 'zammad' }

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

    it 'rejects wrong passwords' do
      pw_crypted = described_class.crypt(pw_plain)
      expect(described_class.verified?(pw_crypted, 'wrong')).to be false
    end
  end

  describe '::hashed_argon2?' do
    it 'detects argon2 hashes' do
      expect(described_class).to be_hashed_argon2(described_class.crypt(pw_plain))
    end

    it 'does not detect other hashes', :aggregate_failures do
      expect(described_class).not_to be_hashed_argon2(described_class.sha2(pw_plain))
      expect(described_class).not_to be_hashed_argon2(pw_plain)
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
