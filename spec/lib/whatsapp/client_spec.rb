# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Client, :aggregate_failures do
  let(:access_token) { '1234' }

  describe '#new' do
    context 'with expected options' do
      it 'creates an instance' do
        expect(described_class.new(access_token:)).to be_a(described_class)
      end
    end

    context 'without expected options' do
      it 'raises an error' do
        expect { described_class.new(access_token: nil) }.to raise_error(ArgumentError, "The required parameter 'access_token' is missing.")
      end
    end
  end
end
