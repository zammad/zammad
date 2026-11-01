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
      [{ 'Content-Type' => 'image/png' }, 'image/png'],
      [{ 'Content-Type' => 'image/png; name=image.png' }, 'image/png'],
      [{ 'Content-Type' => 'image/gif; name=image.png' }, 'image/gif'],
      [{ 'Content-Type' => 'image/jpeg; name=image010.jpg' }, 'image/jpeg'],
      [{ 'Mime-Type' => 'image/png' }, 'image/png'],
    ].each do |preferences, expected_type|
      it "normalizes #{preferences} to #{expected_type}" do
        image = Store.new(
          filename:    'image.png',
          preferences:,
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
