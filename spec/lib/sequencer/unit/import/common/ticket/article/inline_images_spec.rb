# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Ticket::Article::InlineImages do
  describe '.inline_data' do
    let(:image_data) { 'x' * 1500 }
    let(:data_uri)   { "data:image/png;base64,#{Base64.strict_encode64(image_data)}" }

    def image_url(number)
      "https://example.zendesk.com/attachments/token/image#{number}/?name=image.png"
    end

    before do
      stub_const("#{described_class}::INLINE_DATA_CACHE_SIZE", 10.kilobytes)
      described_class.instance_variable_set(:@inline_data_cache, nil)
      allow(described_class).to receive(:download).and_return(image_data)
    end

    after do
      described_class.instance_variable_set(:@inline_data_cache, nil)
    end

    it 'downloads a repeated image only once', :aggregate_failures do
      expect(described_class.inline_data(image_url(1))).to eq(data_uri)
      expect(described_class.inline_data(image_url(1))).to eq(data_uri)
      expect(described_class).to have_received(:download).with(image_url(1)).once
    end

    it 'does not cache an image that could not be downloaded' do
      allow(described_class).to receive(:download).and_return(nil)
      2.times { described_class.inline_data(image_url('failed')) }
      expect(described_class).to have_received(:download).with(image_url('failed')).twice
    end

    it 'does not keep more images than fit into its size' do
      urls = (1..50).map { |number| image_url(number) }
      urls.each { |url| described_class.inline_data(url) }
      urls.reverse_each { |url| described_class.inline_data(url) }

      images_that_fit = 10.kilobytes / data_uri.bytesize
      expect(described_class).to have_received(:download).at_least((urls.size * 2) - images_that_fit).times
    end

    it 'evicts the least recently used image first', :aggregate_failures do
      (1..3).each { |number| described_class.inline_data(image_url(number)) }
      described_class.inline_data(image_url(1))
      (4..5).each { |number| described_class.inline_data(image_url(number)) }

      described_class.inline_data(image_url(1))
      described_class.inline_data(image_url(2))

      expect(described_class).to have_received(:download).with(image_url(1)).once
      expect(described_class).to have_received(:download).with(image_url(2)).twice
    end
  end
end
