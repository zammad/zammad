# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/password_policy/error_examples'

RSpec.describe PasswordPolicy::MaxLength do
  let(:long_string) { Faker::Lorem.characters(number: 1_111) }

  it_behaves_like 'declaring an error'

  describe '.applicable?' do
    it 'returns true' do
      expect(described_class).to be_applicable
    end
  end

  describe '#valid?' do
    it 'long string is invalid' do
      instance = described_class.new long_string
      expect(instance).not_to be_valid
    end

    it 'short string is valid' do
      instance = described_class.new Faker::Lorem.sentence
      expect(instance).to be_valid
    end
  end

  describe '#error' do
    it 'includes value of MAX_LENGTH' do
      instance = described_class.new(long_string)
      expect(instance.error.last).to eq described_class::MAX_LENGTH
    end
  end

  describe '.valid?' do
    it 'long string is invalid' do
      expect(described_class).not_to be_valid(long_string)
    end

    it 'short string is valid' do
      expect(described_class).to be_valid(Faker::Lorem.sentence)
    end
  end
end
