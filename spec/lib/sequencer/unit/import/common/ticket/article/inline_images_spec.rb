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
  end
end
