# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::BinaryStringType do
  context 'when receiving a Base64 string' do
    let(:input)  { Base64.strict_encode64(result) }
    let(:result) { 'my unicode string ø' }

    context 'without prefix' do
      it 'transforms input correctly' do
        expect(described_class.coerce_input(input).b).to eq(result.b)
      end
    end

    context 'with valid data: URL prefix' do
      let(:input_with_prefix) { "data:mime/type;base64,#{input}" }

      it 'transforms input correctly' do
        expect(described_class.coerce_input(input).b).to eq(result.b)
      end
    end

    context 'with invalid data: URL prefix' do
      let(:input_with_prefix) { "data:,#{input}" }

      it 'raises an error' do
        expect { described_class.coerce_input(input_with_prefix).b }.to raise_error(ArgumentError)
      end
    end

    context 'with non-base64 data' do
      let(:raw_input) { 'some string' }

      it 'raises an error' do
        expect { described_class.coerce_input(raw_input).b }.to raise_error(ArgumentError)
      end
    end
  end

  context 'when sending a string' do
    let(:input)  { 'my unicode string ø' }
    let(:result) { Base64.strict_encode64(input) }

    it 'transforms input correctly' do
      expect(described_class.coerce_result(input).b).to eq(result.b)
    end
  end
end
