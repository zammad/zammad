# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5015MigrateIssueLinks, searchindex: true, type: :db_migration do
  context 'when there are some tickets to migrate' do
    let!(:ticket_without)               { create(:ticket, title: 'title1', preferences: {}, updated_at: 2.days.ago) }
    let!(:ticket_gitlab)                { create(:ticket, title: 'title2', preferences: { gitlab: { issue_links: ['https://git.zammad.com/zammad/zammad-gitlab-integration/-/issues/1'] } }, updated_at: 2.days.ago) }
    let!(:ticket_gitlab_broken)         { create(:ticket, title: 'title2', preferences: { gitlab: { issue_links: ['https://git.zammad.com/zammad/zammad-gitlab-integration/-/issues/1111111111'] } }, updated_at: 2.days.ago) }
    let!(:ticket_github)                { create(:ticket, title: 'title3', preferences: { github: { issue_links: ['https://github.com/zammad/zammad/issues/1575'] } }, updated_at: 2.days.ago) }
    let!(:ticket_github_broken)         { create(:ticket, title: 'title3', preferences: { github: { issue_links: ['https://github.com/zammad/zammad/issues/157511111111'] } }, updated_at: 2.days.ago) }
    let!(:ticket_github_invalid_format) { create(:ticket, title: 'title3', preferences: { github: { issue_links: ['https://github.com/zammad/zammad/issues/1x'] } }, updated_at: 2.days.ago) }

    before do
      Setting.set('gitlab_integration', true)
      Setting.set('gitlab_config', {
                    api_token: ENV['GITLAB_APITOKEN'],
                    endpoint:  ENV['GITLAB_ENDPOINT'],
                  })
      Setting.set('github_integration', true)
      Setting.set('github_config', {
                    api_token: ENV['GITHUB_APITOKEN'],
                    endpoint:  ENV['GITHUB_ENDPOINT'],
                  })
      searchindex_model_reload([Ticket])
    end

    it 'does not update unrelated ticket' do
      expect { migrate }.to not_change { ticket_without.updated_at }
    end

    it 'does update ticket which is linked with gitlab issue' do
      migrate
      expect(ticket_gitlab.reload.preferences[:gitlab][:gids][0]).to match(%r{gid://})
    end

    it 'does update ticket which is linked with github issue' do
      migrate
      expect(Base64.decode64(ticket_github.reload.preferences[:github][:gids][0])).to match(%r{Issue})
    end

    it 'does not update ticket which is linked with gitlab issue' do
      migrate
      expect { migrate }.to not_change { ticket_gitlab_broken.updated_at }
    end

    it 'does not update ticket which is linked with github issue' do
      migrate
      expect { migrate }.to not_change { ticket_github_broken.updated_at }
    end

    it 'does not update ticket which is invalid linked with github issue' do
      migrate
      expect { migrate }.to not_change { ticket_github_invalid_format.updated_at }
    end
  end
end
