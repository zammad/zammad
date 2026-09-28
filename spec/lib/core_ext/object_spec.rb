# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Object do
  describe '#to_utf8 (deprecated)' do
    let(:deprecator) { instance_double(ActiveSupport::Deprecation, warn: nil) }

    before { allow(ActiveSupport::Deprecation).to receive(:new).and_return(deprecator) }

    it 'warns about the deprecation' do
      'hello'.to_utf8

      expect(deprecator).to have_received(:warn).once
    end

    it 'delegates to TextEncoding' do
      string = 'Tschüss!'.encode(Encoding::ISO_8859_2)

      expect(string.to_utf8(from: 'iso-8859-2')).to eq('Tschüss!')
    end

    it 'coerces the receiver to a string first' do
      expect(nil.to_utf8).to eq('')
    end
  end
end
