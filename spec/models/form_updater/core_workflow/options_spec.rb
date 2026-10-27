# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::CoreWorkflow::Options do
  subject(:field) do
    described_class.perform(perform_result:, result:, relation_fields: {}, object:)
    result.fetch('example')
  end

  let(:result)             { {} }
  let(:object)             { nil }
  let(:options)            { { 'current' => 'Current' } }
  let(:values)             { %w[current unknown] }
  let(:historical_options) { {} }
  let(:perform_result) do
    {
      restrict_values:    { 'example' => values },
      all_options:        { 'example' => options },
      historical_options: historical_options,
    }
  end

  it 'omits unknown options when the field has no option history' do
    expect(field).to include(
      options:                 [{ value: 'current', label: 'Current' }],
      rejectNonExistentValues: true,
    )
  end

  context 'with boolean option keys from YAML storage' do
    let(:options) { { false => 'no', true => 'yes' } }
    let(:values)  { %w[false true] }

    it 'returns both option labels' do
      expect(field[:options]).to eq([
                                      { value: 'false', label: 'no' },
                                      { value: 'true', label: 'yes' },
                                    ])
    end
  end

  context 'with integer option keys from YAML storage' do
    let(:options) { { 1 => 'One' } }
    let(:values)  { ['1'] }

    it 'returns the option label' do
      expect(field[:options]).to eq([{ value: '1', label: 'One' }])
    end
  end

  context 'when the current value is unknown and the field has no option history' do
    let(:object) { { 'example' => 'unknown' } }

    it 'allows the frontend to retain the current value' do
      expect(field[:rejectNonExistentValues]).to be false
    end
  end

  context 'with a historical option' do
    let(:historical_options) { { 'example' => { 'unknown' => 'Previous' } } }

    it 'allows the frontend to retain the historical value' do
      expect(field[:rejectNonExistentValues]).to be false
    end
  end

  context 'with integer historical option keys from YAML storage' do
    let(:values)             { %w[current 1] }
    let(:historical_options) { { 'example' => { 1 => 'Previous' } } }

    it 'allows the frontend to retain the historical value' do
      expect(field[:rejectNonExistentValues]).to be false
    end
  end
end
