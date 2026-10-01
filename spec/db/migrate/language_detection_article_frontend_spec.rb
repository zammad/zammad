# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe LanguageDetectionArticleFrontend, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'language_detection_article') }

  before do
    setting.update!(frontend: false, preferences: {})
    migrate
  end

  it 'serves the setting to logged-in clients', :aggregate_failures do
    expect(setting.reload.frontend).to be(true)
    expect(setting.preferences).to include(authentication: true)
  end
end
