require 'rails_helper'

RSpec.describe Ldap::Guid do

  let(:string) { 'f742b361-32c6-4a92-baaa-eaae7df657ee' }
  let(:hex) { "a\xB3B\xF7\xC62\x92J\xBA\xAA\xEA\xAE}\xF6W\xEE".b }

  context '.valid?' do

    it 'responds to .valid?' do
      expect(described_class).to respond_to(:valid?)
    end

    it 'detects valid uid string' do
      expect(described_class.valid?(string)).to be true
    end

    it 'detects invalid uid string' do
      invalid = 'AC2342'
      expect(described_class.valid?(invalid)).to be false
    end
  end

  context '.hex' do

    it 'responds to .hex' do
      expect(described_class).to respond_to(:hex)
    end

    it 'tunnels to instance method' do

      instance = double()
      expect(instance).to receive(:hex)
      expect(described_class).to receive(:new).with(string).and_return(instance)

      described_class.hex(string)
    end
  end

  context '.string' do

    it 'responds to .string' do
      expect(described_class).to respond_to(:string)
    end

    it 'tunnels to instance method' do

      instance = double()
      expect(instance).to receive(:string)
      expect(described_class).to receive(:new).with(hex).and_return(instance)

      described_class.string(hex)
    end
  end

  context '#string' do

    let(:instance) { described_class.new(hex) }

    it 'responds to #string' do
      expect(instance).to respond_to(:string)
    end

    it 'converts to string' do
      expect(instance.string).to eq(string)
    end
  end

  context '#hex' do

    let(:instance) { described_class.new(string) }

    it 'responds to #hex' do
      expect(instance).to respond_to(:hex)
    end

    it 'converts to hex' do
      expect(instance.hex).to eq(hex)
    end
  end

end
