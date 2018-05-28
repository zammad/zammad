require 'rails_helper'

RSpec.describe Cti::Log do
  subject { create(:cti_log, **factory_attributes) }
  let(:factory_attributes) { {} }

  context 'with complete, E164 international numbers' do
    let(:factory_attributes) { { from: '4930609854180', to: '4930609811111' } }

    describe '#from_pretty' do
      it 'gives the number in prettified format' do
        expect(subject.from_pretty).to eq('+49 30 609854180')
      end
    end

    describe '#to_pretty' do
      it 'gives the number in prettified format' do
        expect(subject.to_pretty).to eq('+49 30 609811111')
      end
    end
  end

  context 'with private network numbers' do
    let(:factory_attributes) { { from: '007', to: '008' } }

    describe '#from_pretty' do
      it 'gives the number unaltered' do
        expect(subject.from_pretty).to eq('007')
      end
    end

    describe '#to_pretty' do
      it 'gives the number unaltered' do
        expect(subject.to_pretty).to eq('008')
      end
    end
  end

  describe '#to_json' do
    let(:virtual_attributes) { %w[from_pretty to_pretty] }

    it 'includes virtual attributes' do
      expect(subject.as_json).to include(*virtual_attributes)
    end
  end
end
