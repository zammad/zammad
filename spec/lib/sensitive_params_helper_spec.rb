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

    # nested hashes with indifferent access are not copied by #with_indifferent_access
    it 'does not modify the given payload' do
      payload = { another: { test: 'BAR' }.with_indifferent_access }

      expect { instance.mask(payload) }.not_to change { payload.dig(:another, :test) }
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

    it 'clears nested attribute if the original is not a hash' do
      expect(instance.unmask(payload_masked, sample_klass.new('old-FOO', 'not-a-hash', 'no')))
        .to include('another' => { 'test' => nil })
    end

    # nested hashes with indifferent access are not copied by #with_indifferent_access
    it 'does not modify the given params' do
      params = { another: { test: described_class::SENSITIVE_MASK }.with_indifferent_access }

      expect { instance.unmask(params, object) }.not_to change { params.dig(:another, :test) }
    end
  end

  context 'with an array wildcard attribute' do
    let(:attributes) { ['items[].test'] }

    describe '#mask' do
      let(:payload) { { items: [{ test: 'FOO', nonsensitive: 'yes' }, { test: 'BAR' }] } }

      it 'masks the attribute in every array element' do
        expect(instance.mask(payload)['items']).to eq(
          [
            { 'test' => described_class::SENSITIVE_MASK, 'nonsensitive' => 'yes' },
            { 'test' => described_class::SENSITIVE_MASK },
          ]
        )
      end

      # array elements with indifferent access are not copied by #with_indifferent_access
      it 'does not modify the given payload' do
        payload = { items: [{ test: 'FOO' }.with_indifferent_access] }

        expect { instance.mask(payload) }.not_to change { payload[:items].first[:test] }
      end

      it 'does not add mask if attribute was not present' do
        expect(instance.mask({ items: [{ nonsensitive: 'yes' }] })['items'].first.keys).to eq(%w[nonsensitive])
      end

      it 'ignores a value which is not an array' do
        expect(instance.mask({ items: { test: 'FOO' } })['items']).to eq({ 'test' => 'FOO' })
      end
    end

    describe '#unmask' do
      let(:object) { { items: [{ id: 1, test: 'old-FOO' }, { id: 2, test: 'old-BAR' }] } }

      it 'unmasks the attribute in every array element' do
        params = { items: [{ id: 1, test: described_class::SENSITIVE_MASK }, { id: 2, test: described_class::SENSITIVE_MASK }] }

        expect(instance.unmask(params, object)['items']).to eq(
          [{ 'id' => 1, 'test' => 'old-FOO' }, { 'id' => 2, 'test' => 'old-BAR' }]
        )
      end

      it 'does not change array elements which are not masked' do
        params = { items: [{ id: 1, test: 'new-FOO' }, { id: 2, test: described_class::SENSITIVE_MASK }] }

        expect(instance.unmask(params, object)['items']).to eq(
          [{ 'id' => 1, 'test' => 'new-FOO' }, { 'id' => 2, 'test' => 'old-BAR' }]
        )
      end

      it 'unmasks by id instead of by position' do
        params = { items: [{ id: 2, test: described_class::SENSITIVE_MASK }, { id: 1, test: described_class::SENSITIVE_MASK }] }

        expect(instance.unmask(params, object)['items']).to eq(
          [{ 'id' => 2, 'test' => 'old-BAR' }, { 'id' => 1, 'test' => 'old-FOO' }]
        )
      end

      it 'clears the value if the id is unknown' do
        params = { items: [{ id: 3, test: described_class::SENSITIVE_MASK }] }

        expect(instance.unmask(params, object)['items']).to eq([{ 'id' => 3, 'test' => nil }])
      end

      it 'clears the value if the element has no id' do
        params = { items: [{ test: described_class::SENSITIVE_MASK }] }

        expect(instance.unmask(params, object)['items']).to eq([{ 'test' => nil }])
      end

      it 'ignores an original element which is not a hash' do
        params = { items: [{ id: 1, test: described_class::SENSITIVE_MASK }] }

        expect(instance.unmask(params, { items: ['not-a-hash'] })['items']).to eq([{ 'id' => 1, 'test' => nil }])
      end
    end
  end
end
