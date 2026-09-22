# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::ContentTranslationAuto do
  subject(:service) { described_class.with_current_user(agent) }

  let(:agent) { create(:agent, preferences: { 'locale' => 'en-us' }) }

  before { Setting.set('content_translation_ticket_article_auto', true) }

  it 'remembers that whole tickets are translated', :aggregate_failures do
    service.execute(enabled: true)

    expect(agent.reload.preferences['content_translation_auto']).to be(true)
    expect(agent.preferences['locale']).to eq('en-us')
  end

  it 'remembers that they are not' do
    agent.preferences['content_translation_auto'] = true
    agent.save!

    service.execute(enabled: false)

    expect(agent.reload.preferences['content_translation_auto']).to be(false)
  end

  context 'when the user may not translate automatically' do
    before { Setting.set('content_translation_ticket_article_auto', false) }

    it 'refuses to remember it' do
      expect { service.execute(enabled: true) }
        .to raise_error(Exceptions::Forbidden)
        .and not_change { agent.reload.preferences }
    end
  end

  it 'requires a current user' do
    expect { described_class.execute(enabled: true) }
      .to raise_error(%r{Current user is required})
  end
end
