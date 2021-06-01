# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/password_policy/error_examples'

RSpec.describe PasswordPolicy::Length do
  it_behaves_like 'declaring an error'

  describe '.applicable?' do
    it "returns true when Setting 'password_min_size' is zero" do
      Setting.set('password_min_size', 0)
      expect(described_class).to be_applicable
    end

    it "returns true when Setting 'password_min_size' is 10" do
      Setting.set('password_min_size', 10)
      expect(described_class).to be_applicable
    end
  end

  describe '#valid?' do
    it "valid when password is longer than Setting 'password_min_size'" do
      Setting.set('password_min_size', 2)
      instance = described_class.new('good')
      expect(instance).to be_valid
    end

    it "not valid when password is shorter than Setting 'password_min_size'" do
      Setting.set('password_min_size', 2)
      instance = described_class.new('g')
      expect(instance).not_to be_valid
    end

    it "valid when password is exactly Setting 'password_min_size'" do
      Setting.set('password_min_size', 4)
      instance = described_class.new('good')
      expect(instance).to be_valid
    end

    it "valid when Setting 'password_min_size' is zero" do
      Setting.set('password_min_size', 0)
      instance = described_class.new('good')
      expect(instance).to be_valid
    end
  end

  describe 'error' do
    it "includes value of Setting 'password_min_size'" do
      Setting.set('password_min_size', 123)
      instance = described_class.new('')
      expect(instance.error.last).to be(123)
    end
  end
end
