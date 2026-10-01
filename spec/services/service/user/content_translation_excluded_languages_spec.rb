# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::ContentTranslationExcludedLanguages do
  subject(:service) { described_class.with_current_user(agent) }

  let(:agent) { create(:agent, preferences: { 'locale' => 'en-us' }) }

  before { Setting.set('content_translation_ticket_article_auto', true) }

  it 'remembers the languages', :aggregate_failures do
    service.execute(languages: %w[en zh-Hant])

    expect(agent.reload.preferences['content_translation_excluded_languages']).to eq(%w[en zh-Hant])
    expect(agent.preferences['locale']).to eq('en-us')
  end

  it 'remembers that no language is excluded' do
    agent.preferences['content_translation_excluded_languages'] = %w[en]
    agent.save!

    service.execute(languages: [])

    expect(agent.reload.preferences['content_translation_excluded_languages']).to eq([])
  end

  it 'refuses a regional locale' do
    expect { service.execute(languages: %w[en en-gb]) }
      .to raise_error(ActiveRecord::RecordNotFound)
      .and not_change { agent.reload.preferences }
  end

  it 'refuses Chinese without its writing system' do
    expect { service.execute(languages: %w[zh]) }
      .to raise_error(ActiveRecord::RecordNotFound)
      .and not_change { agent.reload.preferences }
  end

  it 'refuses a language without an active locale' do
    Locale.find_by(locale: 'de-de').update!(active: false)

    expect { service.execute(languages: %w[de]) }
      .to raise_error(ActiveRecord::RecordNotFound)
      .and not_change { agent.reload.preferences }
  end

  context 'when the user may not translate automatically' do
    before { Setting.set('content_translation_ticket_article_auto', false) }

    it 'refuses to remember them' do
      expect { service.execute(languages: %w[en]) }
        .to raise_error(Exceptions::Forbidden)
        .and not_change { agent.reload.preferences }
    end
  end

  it 'requires a current user' do
    expect { described_class.execute(languages: %w[en]) }
      .to raise_error(%r{Current user is required})
  end
end
