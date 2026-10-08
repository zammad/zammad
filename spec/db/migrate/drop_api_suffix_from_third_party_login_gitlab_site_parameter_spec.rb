# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DropApiSuffixFromThirdPartyLoginGitLabSiteParameter, type: :db_migration do
  def site_placeholder
    Setting.find_by(name: 'auth_gitlab_credentials').options[:form].find { |field| field[:name] == 'site' }[:placeholder]
  end

  before do
    setting = Setting.find_by(name: 'auth_gitlab_credentials')
    setting.options[:form].find { |field| field[:name] == 'site' }[:placeholder] = 'https://gitlab.YOURDOMAIN.com/api/v4'
    setting.save!

    Setting.set('auth_gitlab_credentials', { site: 'https://git.example.com/api/v4' })
  end

  it 'does migrate auth_gitlab_credentials setting placeholder' do
    expect { migrate }
      .to change { site_placeholder }
      .from('https://gitlab.YOURDOMAIN.com/api/v4')
      .to('https://gitlab.YOURDOMAIN.com/')
  end

  it 'does migrate auth_gitlab_credentials setting site value' do
    expect { migrate }
      .to change { Setting.get('auth_gitlab_credentials')['site'] }
      .from('https://git.example.com/api/v4')
      .to('https://git.example.com/')
  end
end
