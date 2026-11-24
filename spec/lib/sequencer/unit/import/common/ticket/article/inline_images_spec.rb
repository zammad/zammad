# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Ticket::Article::InlineImages do
  describe '.inline_data' do
    let(:log_context) { { ticket_id: 123, message_id: 456 } }

    context 'with a valid image URL' do
      let(:image_url) { 'https://example.zendesk.com/attachments/token/valid%22%20/?name=image.png' }

      before do
        stub_request(:get, image_url).to_return(status: 200, body: '123')
        allow(UserAgent).to receive(:get).and_call_original
      end

      it 'downloads the image from the unchanged URL and returns it as data URI', :aggregate_failures do
        expect(described_class.inline_data(image_url, log_context:)).to eq('data:image/png;base64,MTIz')
        expect(UserAgent).to have_received(:get).with(image_url, {}, anything)
      end
    end

    context 'with an image URL that is not a valid URI' do
      before do
        allow(Rails.logger).to receive(:warn)
      end

      shared_examples 'skipping the image' do
        it 'skips the image instead of raising an error' do
          expect(described_class.inline_data(image_url, log_context:)).to be_nil
        end

        it 'logs a warning that identifies the article but not the URL' do
          described_class.inline_data(image_url, log_context:)
          expect(Rails.logger).to have_received(:warn)
            .with('Skipping inline image, its URL is not a valid URI (ticket_id: 123, message_id: 456).')
        end
      end

      context 'when it contains a quote' do
        let(:image_url) { 'https://example.zendesk.com/attachments/token/quote"/?name=image.png' }

        include_examples 'skipping the image'
      end

      context 'when it contains a line break followed by encoded indentation' do
        let(:image_url) { "https://example.zendesk.com/attachments/token%22\n%20%20%20%20/abc123/?name=ok.png" }

        include_examples 'skipping the image'
      end
    end

    context 'with many images' do
      let(:unit_class) { Class.new(described_class) }
      let(:image_data) { 'x' * 1500 }
      let(:data_uri)   { "data:image/png;base64,#{Base64.strict_encode64(image_data)}" }

      def numbered_url(number)
        "https://example.zendesk.com/attachments/token/image#{number}/?name=image.png"
      end

      before do
        stub_const("#{described_class}::INLINE_DATA_CACHE_SIZE", 10.kilobytes)
        allow(unit_class).to receive(:download).and_return(image_data)
      end

      it 'downloads a repeated image only once', :aggregate_failures do
        expect(unit_class.inline_data(numbered_url(1))).to eq(data_uri)
        expect(unit_class.inline_data(numbered_url(1))).to eq(data_uri)
        expect(unit_class).to have_received(:download).with(numbered_url(1)).once
      end

      it 'does not cache an image that could not be downloaded' do
        allow(unit_class).to receive(:download).and_return(nil)
        2.times { unit_class.inline_data(numbered_url('failed')) }
        expect(unit_class).to have_received(:download).with(numbered_url('failed')).twice
      end

      it 'does not keep more images than fit into its size' do
        urls = (1..50).map { |number| numbered_url(number) }
        urls.each { |url| unit_class.inline_data(url) }
        urls.reverse_each { |url| unit_class.inline_data(url) }

        images_that_fit = 10.kilobytes / data_uri.bytesize
        expect(unit_class).to have_received(:download).at_least((urls.size * 2) - images_that_fit).times
      end

      it 'evicts the least recently used image first', :aggregate_failures do
        (1..3).each { |number| unit_class.inline_data(numbered_url(number)) }
        unit_class.inline_data(numbered_url(1))
        (4..5).each { |number| unit_class.inline_data(numbered_url(number)) }

        unit_class.inline_data(numbered_url(1))
        unit_class.inline_data(numbered_url(2))

        expect(unit_class).to have_received(:download).with(numbered_url(1)).once
        expect(unit_class).to have_received(:download).with(numbered_url(2)).twice
      end
    end
  end
end
