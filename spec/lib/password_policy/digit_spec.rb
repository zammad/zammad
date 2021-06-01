# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/password_policy/error_examples'

RSpec.describe PasswordPolicy::Digit do
  it_behaves_like 'declaring an error'

  describe '.applicable?' do
    it "returns false when Setting 'password_need_digit' is disabled" do
      Setting.set('password_need_digit', 0)
      expect(described_class).not_to be_applicable
    end

    it "returns true when Setting 'password_need_digit' is enabled" do
      Setting.set('password_need_digit', 1)
      expect(described_class).to be_applicable
    end
  end

  describe '#valid?' do
    it 'valid when digit is included' do
      instance = described_class.new('goodPW!!1111')
      expect(instance).to be_valid
    end

    it 'not valid when only letters' do
      instance = described_class.new('notsogoodpw')
      expect(instance).not_to be_valid
    end

    it 'not valid when includes special characters' do
      instance = described_class.new('notsogoodpw@#!')
      expect(instance).not_to be_valid
    end
  end
end
