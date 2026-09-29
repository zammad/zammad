# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Feature::OCR, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do
  subject(:ai_service) { described_class.new(context_data:, prompt_image:) }

  let(:prompt_image) { create(:store, :image, data: Rails.root.join('spec/fixtures/files/image/ocr.png').binread) }

  let(:context_data) do
    {
      store: prompt_image,
    }
  end

  before do
    setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
  end

  it 'returns recognized image text' do
    # Line breaks and the doubled "there there's" of the image vary between model runs.
    expect(ai_service.execute.content.squish).to match(
      %r{\ASorry, but the Phoenix is not able to find your page\. Try checking the URL for errors - maybe (there )?there's a tyop, erm, typo!\z}
    )
  end

end
