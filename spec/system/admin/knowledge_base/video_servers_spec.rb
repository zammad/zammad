# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Admin Panel > Knowledge Base > Video servers', type: :system do
  include_context 'basic Knowledge Base'

  before do
    knowledge_base
    visit '/#manage/knowledge_base'
    click_on 'Video Servers'
  end

  it 'adds a new video server' do
    expect(page).to have_text('No self-hosted video servers configured yet')

    click '.js-new'

    in_modal do
      fill_in 'Host', with: 'video.example.com'
      fill_in 'Name', with: 'Example Video Server'
      click '.js-submit'
    end

    expect(page).to have_no_text('No self-hosted video servers configured yet')

    within 'table' do
      expect(page).to have_text('Example Video Server')
        .and have_text('video.example.com')
    end

    expect(Setting.get('kb_self_hosted_video_servers')).to include(
      include(
        name: 'Example Video Server',
        host: 'video.example.com'
      )
    )
  end

  context 'with existing video servers', authenticated_as: :authenticate do
    def authenticate
      Setting.set('kb_self_hosted_video_servers', [
                    { 'host' => 'video.example.com', 'name' => 'PT' },
                    { 'host' => 'cms.example.org', 'name' => 'CMS' }
                  ])
    end

    it 'edits and removes a video server' do
      within 'table' do
        expect(page).to have_text('PT')
          .and have_text('video.example.com')
          .and have_text('CMS')
          .and have_text('cms.example.org')
      end

      find('td', text: 'PT').click

      in_modal do
        fill_in 'Name', with: 'PeerTube'
        click '.js-submit'
      end

      within 'table' do
        expect(page).to have_text('PeerTube')
          .and have_text('video.example.com')
          .and have_no_text('PT')
          .and have_text('CMS')
          .and have_text('cms.example.org')
      end

      expect(Setting.get('kb_self_hosted_video_servers')).to include(
        include(
          name: 'PeerTube',
          host: 'video.example.com'
        ),
        include(
          name: 'CMS',
          host: 'cms.example.org'
        )
      )

      find('tr', text: %r{CMS}).find('.js-remove').click

      in_modal { click '.js-submit' }

      within 'table' do
        expect(page).to have_text('PeerTube')
          .and have_text('video.example.com')
          .and have_no_text('CMS')
          .and have_no_text('cms.example.org')
      end

      expect(Setting.get('kb_self_hosted_video_servers')).to include(
        include(
          name: 'PeerTube',
          host: 'video.example.com'
        )
      ).and(not_include(
              include(
                name: 'CMS',
                host: 'cms.example.org'
              )
            ))
    end
  end
end
