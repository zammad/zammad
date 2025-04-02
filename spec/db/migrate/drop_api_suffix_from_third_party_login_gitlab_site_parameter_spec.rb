# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DropApiSuffixFromThirdPartyLoginGitLabSiteParameter, type: :db_migration do
  before do
    old_auth_gitlab_form = Setting.find_by(name: 'auth_gitlab_credentials').options[:form]
    old_auth_gitlab_form[2][:placeholder] = 'https://gitlab.YOURDOMAIN.com/api/v4'

    Setting.create_or_update(
      title:       __('SAML App Credentials'),
      name:        'auth_saml_credentials',
      area:        'Security::ThirdPartyAuthentication::SAML',
      description: __('Enables user authentication via SAML.'),
      options:     {
        form: old_auth_gitlab_form
      }
    )

    Setting.set('auth_gitlab_credentials', { site: 'https://git.example.com/api/v4' })

    migrate
  end

  it 'does migrate auth_gitlab_credentials setting placeholder' do
    expect(Setting.find_by(name: 'auth_gitlab_credentials').options[:form][2][:placeholder]).to eq('https://gitlab.YOURDOMAIN.com/')
  end

  it 'does migrate auth_gitlab_credentials setting site value' do
    expect(Setting.get('auth_gitlab_credentials')['site']).to eq('https://git.example.com/')
  end
end
