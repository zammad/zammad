# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::ExternalReferences::IssueTracker::Item, integration: true, required_envs: %w[GITHUB_ENDPOINT GITHUB_ISSUE_LINK GITHUB_APITOKEN] do
  subject(:service) { described_class.new(issue_link:, type:) }

  context 'when GitHub is used' do
    let(:type)       { 'github' }
    let(:issue_link) { ENV['GITHUB_ISSUE_LINK'] }

    describe '#execute' do
      context 'when github integration is active' do
        let(:expected_issue) do
          {
            id:         '1575',
            title:      'GitHub integration',
            url:        ENV['GITHUB_ISSUE_LINK'],
            icon_state: 'closed',
            milestone:  '4.0',
            assignees:  ['Thorsten'],
            labels:     [
              {
                color:      '#84b6eb',
                text_color: '#000000',
                title:      'enhancement'
              },
              {
                color:      '#bfdadc',
                text_color: '#000000',
                title:      'integration'
              }
            ],
          }
        end

        before do
          Setting.set('github_integration', true)
          Setting.set('github_config', { 'endpoint' => ENV['GITHUB_ENDPOINT'], 'api_token' => ENV['GITHUB_APITOKEN'] })
        end

        it 'returns a list of issues' do
          expect(service.execute).to eq(expected_issue)
        end
      end
    end
  end
end
