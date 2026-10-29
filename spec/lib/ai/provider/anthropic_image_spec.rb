# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Provider::Anthropic do
  subject(:ai_provider) { described_class.new(config: { token: 'test-key' }) }

  let(:request_bodies) { [] }

  let(:response) do
    UserAgent::Result.new(
      success: true,
      code:    200,
      data:    {
        'content' => [{ 'type' => 'text', 'text' => 'ok' }],
        'usage'   => { 'input_tokens' => 1, 'output_tokens' => 1 },
      },
    )
  end

  before do
    allow(UserAgent).to receive(:post) do |_url, body, _options|
      request_bodies << body
      response
    end
  end

  describe '#ask with image' do
    [
      ['image/png', 'image/png'],
      ['image/png; name=image.png', 'image/png'],
      ['image/gif; name=image.png', 'image/gif'],
      ['image/jpeg; name=image010.jpg', 'image/jpeg'],
    ].each do |content_type, expected_type|
      it "normalizes #{content_type} to #{expected_type}" do
        image = Store.new(
          filename:    'image.png',
          preferences: { 'Content-Type' => content_type },
        )

        allow(image).to receive(:content_ocr).and_return('fake image bytes')

        ai_provider.ask(
          prompt_system: '',
          prompt_user:   'Extract text',
          prompt_image:  image,
        )

        media_type = request_bodies.first.dig(
          :messages, 0, :content, 1, :source, :media_type
        )

        expect(media_type).to eq(expected_type)
      end
    end
  end
end
