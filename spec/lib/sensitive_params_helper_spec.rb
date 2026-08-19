# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SensitiveParamsHelper do
  subject(:instance) { described_class.new(attributes) }

  let(:attributes) { ['test', 'another.test'] }

  describe '#mask' do
    let(:payload_raw)     { { test: 'FOO', another: { test: 'BAR' }, nonsensitive: 'yes' } }
    let(:payload_basic)   { { nonsensitive: 'yes' } }

    it 'masks given attribute' do
      expect(instance.mask(payload_raw)).to include(
        'test'         => described_class::SENSITIVE_MASK,
        'nonsensitive' => 'yes'
      )
    end

    it 'masks nested attribute' do
      expect(instance.mask(payload_raw)).to include(
        'another'      => { 'test' => described_class::SENSITIVE_MASK },
        'nonsensitive' => 'yes'
      )
    end

    it 'does not add mask if attribute was not present' do
      expect(instance.mask(payload_basic).keys).to eq(%w[nonsensitive])
    end

    context 'with unset values' do
      let(:payload_unset) { { test: nil, another: { test: '' }, nonsensitive: 'yes' } }

      it 'does not mask unset attribute' do
        expect(instance.mask(payload_unset)).to include('test' => nil)
      end

      it 'does not mask unset nested attribute' do
        expect(instance.mask(payload_unset)).to include('another' => { 'test' => '' })
      end
    end

    context 'with values which are blank but set' do
      let(:payload_false)      { { test: false, nonsensitive: 'yes' } }
      let(:payload_whitespace) { { test: '   ', nonsensitive: 'yes' } }

      it 'masks a false attribute' do
        expect(instance.mask(payload_false)).to include('test' => described_class::SENSITIVE_MASK)
      end

      it 'masks a whitespace-only attribute' do
        expect(instance.mask(payload_whitespace)).to include('test' => described_class::SENSITIVE_MASK)
      end
    end
  end

  describe '#unmask' do
    let(:payload_masked)  { { test: described_class::SENSITIVE_MASK, another: { test: described_class::SENSITIVE_MASK }, nonsensitive: 'yes' } }
    let(:payload_update)  { { test: 'new-FOO', another: { test: 'new-BAR' }, nonsensitive: 'yes' } }
    let(:object)          { sample_klass.new('old-FOO', { 'test' => 'old-BAR' }, 'no') }
    let(:sample_klass)    { Struct.new(:test, :another, :nonsensitive) }

    it 'unmasks given attribute' do
      expect(instance.unmask(payload_masked, object)).to include(
        'test'         => 'old-FOO',
        'nonsensitive' => 'yes'
      )
    end

    it 'unmasks nested attribute' do
      expect(instance.unmask(payload_masked, object)).to include(
        'another'      => { 'test' => 'old-BAR' },
        'nonsensitive' => 'yes'
      )
    end

    it 'does not change attribute if not masked' do
      expect(instance.unmask(payload_update, object)).to include(
        'test'         => 'new-FOO',
        'nonsensitive' => 'yes'
      )
    end

    it 'does not change nested attribute if not masked' do
      expect(instance.unmask(payload_update, object)).to include(
        'another'      => { 'test' => 'new-BAR' },
        'nonsensitive' => 'yes'
      )
    end
  end
end
