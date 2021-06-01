# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/password_policy/error_examples'

RSpec.describe PasswordPolicy::UpperAndLowerCaseCharacters do
  it_behaves_like 'declaring an error'

  describe '.applicable?' do
    it "returns false when Setting 'password_min_2_lower_2_upper_characters' is disabled" do
      Setting.set('password_min_2_lower_2_upper_characters', 0)
      expect(described_class).not_to be_applicable
    end

    it "returns true when Setting 'password_min_2_lower_2_upper_characters' is enabled" do
      Setting.set('password_min_2_lower_2_upper_characters', 1)
      expect(described_class).to be_applicable
    end
  end

  describe '#valid?' do
    it 'valid when upper and lower letters included' do
      instance = described_class.new('abcDE')
      expect(instance).to be_valid
    end

    it 'valid when upper and lower letters included are non-ASCII' do
      instance = described_class.new('ąčŪŽ')
      expect(instance).to be_valid
    end

    it 'not valid when only upper letters' do
      instance = described_class.new('NOTSOGOODPW')
      expect(instance).not_to be_valid
    end

    it 'not valid when only lower letters' do
      instance = described_class.new('notsogoodpw')
      expect(instance).not_to be_valid
    end

    it 'not valid when only upper letter included' do
      instance = described_class.new('abcD')
      expect(instance).not_to be_valid
    end
  end
end
