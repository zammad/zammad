# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Pseudonymisation do

  describe '.of_hash' do

    let(:source) do
      {
        firstname:    'John',
        lastname:     nil,
        email:        'john.doe@example.com',
        organization: 'Example Inc.',
      }
    end

    let(:result) do
      {
        firstname:    'J*n',
        lastname:     '*',
        email:        'j*e@e*e.com',
        organization: 'E*e I*.',
      }
    end

    it 'creates pseudonymous hash' do
      expect(described_class.of_hash(source)).to eq(result)
    end
  end

  describe '.of_value' do

    context 'when email address is given' do
      let(:source) { 'test@example.com' }

      it 'creates pseudonymous email_address' do
        expect(described_class.of_value(source)).to eq('t*t@e*e.com')
      end
    end

    context 'when string is given' do
      let(:source) { 'Zammad' }

      it 'creates pseudonymous string' do
        expect(described_class.of_value(source)).to eq('Z*d')
      end
    end

    context 'when nil is given' do
      let(:source) { nil }

      it 'returns *' do
        expect(described_class.of_value(source)).to eq('*')
      end
    end
  end

  describe '.of_email_address' do

    let(:source) { 'test@example.com' }

    it 'creates pseudonymous email_address' do
      expect(described_class.of_email_address(source)).to eq('t*t@e*e.com')
    end

    context 'when address is invalid' do

      it 'raises ArgumentError for parsing errors' do
        expect { described_class.of_email_address('i_m_no_address@') }.to raise_exception(ArgumentError)
      end

      it 'raises ArgumentError for string argument' do
        expect { described_class.of_email_address('i_m_no_address') }.to raise_exception(ArgumentError)
      end
    end
  end

  describe '.of_domain' do

    let(:source) { 'zammad.com' }

    it 'creates pseudonymous string with TLD' do
      expect(described_class.of_domain(source)).to eq('z*d.com')
    end

    context 'when no TLD is present' do

      let(:source) { 'localhost' }

      it 'creates pseudonymous string' do
        expect(described_class.of_domain(source)).to eq('l*t')
      end
    end
  end

  describe '.of_string' do

    let(:source) { 'Zammad' }

    it 'creates pseudonymous string' do
      expect(described_class.of_string(source)).to eq('Z*d')
    end

    context 'when only one char long' do
      let(:source) { 'a' }

      it 'returns *' do
        expect(described_class.of_string(source)).to eq('*')
      end
    end

    context 'when multiple sub-strings are given' do
      let(:source) { 'Zammad Foundation' }

      it 'create pseudonymous string for each' do
        expect(described_class.of_string(source)).to eq('Z*d F*n')
      end
    end

    context 'when nil are given' do
      let(:source) { nil }

      it 'returns *' do
        expect(described_class.of_string(source)).to eq('*')
      end
    end
  end
end
