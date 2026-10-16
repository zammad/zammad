# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ImageHelper do
  describe '.data_url_attributes' do
    it 'raises error if empty string given' do
      expect { described_class.data_url_attributes('') }.to raise_error(%r{Unable to parse data url})
    end

    it 'raises error if nil' do
      expect { described_class.data_url_attributes(nil) }.to raise_error(%r{Unable to parse data url})
    end
  end

  describe '.mime_type' do
    it 'detects a png image by its content' do
      expect(described_class.mime_type(Rails.root.join('spec/fixtures/files/image/small.png').binread)).to eq('image/png')
    end

    it 'detects a jpeg image by its content' do
      expect(described_class.mime_type("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00".b)).to eq('image/jpeg')
    end

    it 'returns the binary type for content of no known type' do
      expect(described_class.mime_type('{"took":1}')).to eq('application/octet-stream')
    end

    it 'returns the binary type for empty content' do
      expect(described_class.mime_type('')).to eq('application/octet-stream')
    end
  end
end
