# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3627OutdatedUrlsSecurityPage, type: :db_migration do
  context 'when having outadted url for google oauth2' do
    before do
      setting.preferences[:description_i18n][2] = 'https://console.developers.google.com/apis/credentials'
      setting.save!
    end

    let(:setting) { Setting.find_by(name: 'auth_google_oauth2') }

    it 'change url in preference description placeholder' do
      expect { migrate }.to change { setting.reload.preferences[:description_i18n][2] }.to('https://console.cloud.google.com/apis/credentials')
    end
  end

  context 'when having outadted url for microsoft office365' do
    before do
      setting.preferences[:description_i18n][2] = 'https://apps.dev.microsoft.com'
      setting.save!
    end

    let(:setting) { Setting.find_by(name: 'auth_microsoft_office365') }

    it 'change url in preference description placeholder' do
      expect { migrate }.to change { setting.reload.preferences[:description_i18n][2] }.to('https://portal.azure.com')
    end
  end
end
