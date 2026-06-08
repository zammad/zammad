# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Service::OCR, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do
  subject(:ai_service) { described_class.new(current_user:, context_data:, prompt_image:) }

  let(:current_user) { create(:agent) }
  let(:prompt_image) { create(:store, :image, data: Rails.root.join('spec/fixtures/files/image/ocr.png').binread) }

  let(:context_data) do
    {
      store: prompt_image,
    }
  end

  let(:llm_response) do
    <<~OCR.chomp
      Sorry, but the Phoenix is not able to find your page.
      Try checking the URL for errors - maybe there there's a tyop, erm, typo!
    OCR
  end

  before do
    setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
  end

  it 'returns recognized image text' do
    result = ai_service.execute
    expect(result.content).to eq(llm_response)
  end

end
