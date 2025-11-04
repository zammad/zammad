# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI > Provider', authenticated_as: :admin, type: :system do
  let(:admin)                      { create(:admin) }
  let(:self_hosted)                { false }
  let(:initial_ai_provider_config) { {} }

  before do
    Setting.set('ai_provider_config', initial_ai_provider_config, validate: false)
    Setting.set('ai_provider', initial_ai_provider_config.present?, validate: false)

    if self_hosted
      Setting.set('system_online_service', false)
      Setting.set('developer_mode', false)
    end

    result = UserAgent::Result.new(
      success: true,
      code:    200,
    )

    allow(UserAgent).to receive_messages(get: result, post: result)

    visit '/#ai/provider'
  end

  it 'allows configuring AI provider settings' do
    within :active_content do
      expect(page).to have_text('Provider')
      expect(page).to have_text('This service allows you to connect Zammad with an AI provider.')

      find('select[name=provider]').select('OpenAI')

      fill_in 'token', with: '1234111'

      click '.js-provider-submit'

      await_empty_ajax_queue

      # Verify settings were saved
      expect(Setting.get('ai_provider')).to be(true)
      expect(Setting.get('ai_provider_config')).to include({ provider: 'open_ai', token: '1234111' })
    end
  end

  it 'shows a field for selecting a provider' do
    within :active_content do
      find('select[name=provider]').select('OpenAI')
      expect(page)
        .to have_field('Token')
        .and(have_field('Model', placeholder: AI::Provider::OpenAI::DEFAULT_OPTIONS[:model]))

      find('select[name=provider]').select('Ollama')
      expect(page)
        .to have_field('URL')
        .and(have_field('Model', placeholder: AI::Provider::Ollama::DEFAULT_OPTIONS[:model]))

      find('select[name=provider]').select('Anthropic')
      expect(page)
        .to have_field('Token')
        .and(have_field('Model', placeholder: AI::Provider::Anthropic::DEFAULT_OPTIONS[:model]))

      find('select[name=provider]').select('Azure AI')
      expect(page)
        .to have_field('URL')
        .and(have_field('Token'))
        .and(have_no_field('Model'))

      find('select[name=provider]').select('Zammad AI')
      expect(page)
        .to have_no_field('Token')
        .and(have_no_field('Model'))
        .and(have_no_field('URL'))
    end
  end

  context 'when self-hosted' do
    let(:self_hosted) { true }

    it 'shows Zammad AI Token field' do
      find('select[name=provider]').select('Zammad AI')
      expect(page)
        .to have_field('Token')
        .and(have_no_field('Model'))
        .and(have_no_field('URL'))
    end
  end

  it 'validates required fields' do
    within :active_content do
      find('select[name=provider]').select('OpenAI')

      click '.js-provider-submit'

      expect(page).to have_text('is required')
    end
  end

  it 'saves configuration' do
    allow(AI::Provider::OpenAI).to receive(:ping!).and_return(true)

    token = '123'
    model = 'gpt-123'

    within :active_content do
      find('select[name=provider]').select('OpenAI')
      fill_in 'Token', with: token
      fill_in 'Model', with: model

      click '.js-provider-submit'
    end

    expect(page).to have_text('Update successful.')

    expect(Setting.get('ai_provider')).to be(true)
    expect(Setting.get('ai_provider_config')).to include(provider: 'open_ai', token:, model:)
  end

  context 'with initial configuration' do
    let(:initial_ai_provider_config) do
      { provider: 'open_ai', token: '123' }
    end

    it 'saves clear configuration' do
      find('select[name=provider]').select('-')
      click '.js-provider-submit'

      expect(page).to have_text('Update successful.')

      expect(Setting.get('ai_provider')).to be(false)
      expect(Setting.get('ai_provider_config')).to be_blank
    end
  end

  it 'shows feedback & logs tab with downloads and entries' do
    within :active_content do
      find('.nav-tabs a', text: 'Feedback & Logs').click
    end

    within '#c-feedback-logs' do
      expect(page).to have_text('DOWNLOAD FEEDBACK')
        .and have_text('DOWNLOAD ERROR LOGS')
    end
  end

  context 'when downloading analytics' do
    it 'downloads feedback and error logs' do
      click_on 'Feedback & Logs'

      expect(page).to have_text('This service allows you to download feedback agents provide on AI features and error details about failed AI requests.')

      click '.js-downloadFeedback'

      click '.js-downloadErrorLogs'

      # we can't test the download itself, but we can check if the button is still there so we didn't redirect
      expect(page).to have_text('DOWNLOAD FEEDBACK')
        .and have_text('DOWNLOAD ERROR LOGS')
    end
  end
end
