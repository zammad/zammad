# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::ContentTranslationTargetLocale do
  subject(:service) { described_class.with_current_user(agent) }

  let(:agent) { create(:agent, preferences: { 'locale' => 'en-us' }) }

  it 'remembers the locale' do
    service.execute(target_locale: 'de-de')

    expect(agent.reload.preferences['content_translation_target_locale']).to eq('de-de')
  end

  it 'leaves the other preferences alone' do
    service.execute(target_locale: 'de-de')

    expect(agent.reload.preferences['locale']).to eq('en-us')
  end

  it 'replaces a former target' do
    agent.preferences['content_translation_target_locale'] = 'fr-fr'
    agent.save!

    service.execute(target_locale: 'de-de')

    expect(agent.reload.preferences['content_translation_target_locale']).to eq('de-de')
  end

  it 'refuses an unknown locale' do
    expect { service.execute(target_locale: 'xx-xx') }
      .to raise_error(ActiveRecord::RecordNotFound)
      .and not_change { agent.reload.preferences }
  end

  it 'refuses an inactive locale' do
    Locale.find_by(locale: 'de-de').update!(active: false)

    expect { service.execute(target_locale: 'de-de') }
      .to raise_error(ActiveRecord::RecordNotFound)
      .and not_change { agent.reload.preferences }
  end

  it 'requires a current user' do
    expect { described_class.execute(target_locale: 'de-de') }
      .to raise_error(%r{Current user is required})
  end
end
