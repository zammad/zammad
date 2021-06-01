# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/password_policy/error_examples'

RSpec.describe PasswordPolicy::SpecialCharacter do
  it_behaves_like 'declaring an error'

  describe '.applicable?' do
    it "returns false when Setting 'password_need_special_character' is disabled" do
      Setting.set('password_need_special_character', 0)
      expect(described_class).not_to be_applicable
    end

    it "returns true when Setting 'password_need_digit' is enabled" do
      Setting.set('password_need_special_character', 1)
      expect(described_class).to be_applicable
    end
  end

  describe '#valid?' do
    it 'valid when special character is included' do
      instance = described_class.new('gütenTag')
      expect(instance).to be_valid
    end

    it 'not valid when only letters' do
      instance = described_class.new('notsogoodpw')
      expect(instance).not_to be_valid
    end

    it 'not valid when includes digit' do
      instance = described_class.new('notsogoodpw123')
      expect(instance).not_to be_valid
    end
  end
end
