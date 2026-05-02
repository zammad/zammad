# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Provider::Concerns::HandlesOpenAIMessages do
  subject(:provider) { AI::Provider::CustomOpenAI.new(config: { url: 'http://localhost', token: 'test' }) }

  let(:image_content) { 'fake image bytes' }
  let(:prompt_image) do
    instance_double(Store,
                    is_a?:       true,
                    content_ocr: image_content,
                    preferences: { 'Content-Type' => content_type })
  end

  before do
    allow(prompt_image).to receive(:is_a?).with(Store).and_return(true)
  end

  describe '#messages_for' do
    context 'when Content-Type contains only the MIME type' do
      let(:content_type) { 'image/jpeg' }

      it 'builds the data URI with the plain MIME type' do
        messages = provider.messages_for(prompt_system: '', prompt_user: 'describe', prompt_image:)
        url = messages.last[:content].find { |c| c[:type] == 'image_url' }.dig(:image_url, :url)

        expect(url).to start_with('data:image/jpeg;base64,')
      end
    end

    context 'when Content-Type contains additional parameters' do
      let(:content_type) { 'image/jpeg; name=image010.jpg' }

      it 'strips the parameters and builds a valid data URI', :aggregate_failures do
        messages = provider.messages_for(prompt_system: '', prompt_user: 'describe', prompt_image:)
        url = messages.last[:content].find { |c| c[:type] == 'image_url' }.dig(:image_url, :url)

        expect(url).to start_with('data:image/jpeg;base64,')
        expect(url).not_to include('name=image010.jpg')
      end
    end
  end
end
